module Hacl.Bignum.Montgomery

open FStar.HyperStack
open FStar.HyperStack.ST
open FStar.Mul

open Lib.IntTypes
open Lib.Buffer

open Hacl.Bignum.Definitions
open Hacl.Bignum.Base
open Hacl.Bignum
open Hacl.Impl.Lib

module ST = FStar.HyperStack.ST
module Loops = Lib.LoopCombinators
module LSeq = Lib.Sequence

module S = Hacl.Spec.Bignum.Montgomery
module SB = Hacl.Spec.Bignum

friend Hacl.Spec.Bignum.Montgomery

#reset-options "--z3rlimit 50 --max_fuel 0 --max_ifuel 0"


inline_for_extraction noextract
val mod_inv_u64_:
    alpha:uint64
  -> beta:uint64
  -> ub:lbuffer uint64 1ul
  -> vb:lbuffer uint64 1ul ->
  Stack unit
  (requires fun h -> live h ub /\ live h vb /\ disjoint ub vb)
  (ensures  fun h0 _ h1 -> modifies (loc ub |+| loc vb) h0 h1 /\
    (let (us, vs) =
      Loops.repeat_gen 64 S.mod_inv_u64_t
	(S.mod_inv_u64_f alpha beta)
	(LSeq.index (as_seq h0 ub) 0, LSeq.index (as_seq h0 vb) 0) in
    LSeq.index (as_seq h1 ub) 0 == us /\ LSeq.index (as_seq h1 vb) 0 == vs))

let mod_inv_u64_ alpha beta ub vb =
  [@inline_let]
  let refl h i : GTot (uint64 & uint64) = LSeq.index (as_seq h ub) 0, LSeq.index (as_seq h vb) 0 in
  [@inline_let]
  let footprint i = loc ub |+| loc vb in
  [@inline_let]
  let spec h0 = S.mod_inv_u64_f alpha beta in
  let h0 = ST.get () in
  loop h0 64ul S.mod_inv_u64_t refl footprint spec
  (fun i ->
    Loops.unfold_repeat_gen 64 S.mod_inv_u64_t (spec h0) (refl h0 0) (v i);
    let us = ub.(0ul) in
    let vs = vb.(0ul) in
    let u_is_odd = u64 0 -. (us &. u64 1) in
    let beta_if_u_is_odd = beta &. u_is_odd in
    ub.(0ul) <- ((us ^. beta_if_u_is_odd) >>. 1ul) +. (us &. beta_if_u_is_odd);

    let alpha_if_u_is_odd = alpha &. u_is_odd in
    vb.(0ul) <- (vs >>. 1ul) +. alpha_if_u_is_odd
  )


[@CInline]
let mod_inv_u64 n0 =
  push_frame ();
  let alpha = u64 1 <<. 63ul in
  let beta = n0 in
  let ub = create 1ul (u64 0) in
  let vb = create 1ul (u64 0) in
  ub.(0ul) <- u64 1;
  vb.(0ul) <- u64 0;
  mod_inv_u64_ alpha beta ub vb;
  let res = vb.(0ul) in
  pop_frame ();
  res



inline_for_extraction noextract
val mont_reduction_f:
    nLen:size_t
  -> rLen:size_t{v rLen = v nLen + 1 /\ v rLen + v rLen <= max_size_t}
  -> n:lbignum nLen
  -> nInv_u64:uint64
  -> j:size_t{v j < v rLen}
  -> res:lbignum (rLen +! rLen) ->
  Stack unit
  (requires fun h -> live h n /\ live h res /\ disjoint n res)
  (ensures  fun h0 _ h1 -> modifies (loc res) h0 h1 /\
    as_seq h1 res == S.mont_reduction_f #(v nLen) #(v rLen) (as_seq h0 n) nInv_u64 (v j) (as_seq h0 res))

let mont_reduction_f nLen rLen n nInv_u64 j res =
  push_frame ();
  let qj = nInv_u64 *. res.(j) in
  let c = bn_mul1_lshift_add_in_place nLen n qj (rLen +! rLen) j res in
  let c = create 1ul c in

  let h0 = ST.get () in
  let res2 = sub res (j +! nLen) (rLen +! rLen -! j -! nLen) in
  let _ = update_sub_f_carry #uint64 #carry h0 res (j +! nLen) (rLen +! rLen -! j -! nLen)
    (fun h -> SB.bn_add (as_seq h0 res2) (as_seq h0 c))
    (fun _ -> bn_add (rLen +! rLen -! j -! nLen) res2 1ul c res2) in
  pop_frame ()


[@CInline]
let mont_reduction nLen rLen n nInv_u64 c res =
  [@ inline_let]
  let spec h = S.mont_reduction_f #(v nLen) #(v rLen) (as_seq h n) nInv_u64 in

  let h0 = ST.get () in
  loop1 h0 rLen c spec
  (fun j ->
    Loops.unfold_repeati (v rLen) (spec h0) (as_seq h0 c) (v j);
    mont_reduction_f nLen rLen n nInv_u64 j c
  );
  bn_rshift (rLen +! rLen) c rLen res


[@CInline]
let to_mont nLen rLen n nInv_u64 r2 a aM =
  push_frame ();
  let tmp = create (rLen +! rLen) (u64 0) in

  let h0 = ST.get () in
  let c = sub tmp 0ul (nLen +! nLen) in
  update_sub_f h0 tmp 0ul (nLen +! nLen)
    (fun h -> SB.bn_mul (as_seq h0 a) (as_seq h0 r2))
    (fun _ -> bn_mul nLen a nLen r2 c);
  mont_reduction nLen rLen n nInv_u64 tmp aM; // aM = c % n
  pop_frame ()


[@CInline]
let from_mont nLen rLen n nInv_u64 aM a =
  push_frame ();
  let tmp = create (rLen +! rLen) (u64 0) in
  update_sub tmp 0ul rLen aM;
  let a' = create rLen (u64 0) in
  mont_reduction nLen rLen n nInv_u64 tmp a';
  copy a (sub a' 0ul nLen);
  pop_frame ()


[@CInline]
let mont_mul nLen rLen n nInv_u64 aM bM resM =
  push_frame ();
  let c = create (rLen +! rLen) (u64 0) in
  bn_mul rLen aM rLen bM c; // c = aM * bM
  mont_reduction nLen rLen n nInv_u64 c resM; // resM = c % n
  pop_frame ()
