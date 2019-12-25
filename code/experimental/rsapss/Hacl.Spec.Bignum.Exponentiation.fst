module Hacl.Spec.Bignum.Exponentiation

open FStar.Mul

open Lib.IntTypes
open Lib.Sequence
open Lib.LoopCombinators

open Hacl.Spec.Bignum.Definitions
open Hacl.Spec.Bignum
open Hacl.Spec.Bignum.Montgomery

module BL = Hacl.Spec.Exponentiation.Lemmas
module M = Hacl.Spec.Montgomery.Lemmas

#reset-options "--z3rlimit 50 --max_fuel 0 --max_ifuel 0"

val bn_mod_exp_f:
    #nLen:size_nat
  -> #rLen:size_nat{rLen = nLen + 1 /\ rLen + rLen <= max_size_t}
  -> n:lbignum nLen
  -> mu:uint64
  -> bBits:size_pos
  -> bLen:size_nat{bLen == blocks bBits 64}
  -> b:lbignum bLen
  -> i:nat{i < bBits}
  -> aM_accM: tuple2 (lbignum rLen) (lbignum rLen) ->
  tuple2 (lbignum rLen) (lbignum rLen)

let bn_mod_exp_f #nLen #rLen n mu bBits bLen b i (aM, accM) =
  let accM = if (bn_is_bit_set #bLen b i) then mont_mul n mu aM accM else accM in // acc = (acc * a) % n
  let aM = mont_mul n mu aM aM in // a = (a * a) % n
  (aM, accM)


let bn_mod_exp modBits nLen n r2 a bBits b =
  let rLen = nLen + 1 in
  let bLen = blocks bBits 64 in

  let acc  = create nLen (u64 0) in
  let acc = acc.[0] <- u64 1 in
  let mu = mod_inv_u64 n.[0] in

  let aM = to_mont n mu r2 a in
  let accM = to_mont n mu r2 acc in
  let (aM, accM) = repeati bBits (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM, accM) in
  let res = from_mont n mu accM in
  bn_sub_mask n res

///
///  Lemma (bn_v (bn_mod_exp modBits nLen n r2 a bBits b) == Spec.RSAPSS.fpow #(bn_v n) (bn_v a) (bn_v b))
///

val bn_mod_exp_f_lemma:
    #nLen:size_nat
  -> #rLen:size_nat{rLen = nLen + 1 /\ rLen + rLen <= max_size_t}
  -> n:lbignum nLen
  -> mu:uint64
  -> bBits:size_pos
  -> bLen:size_nat{bLen == blocks bBits 64}
  -> b:lbignum bLen
  -> i:nat{i < bBits}
  -> aM_accM0: tuple2 (lbignum rLen) (lbignum rLen) -> Lemma
  (requires
   (let (aM0, accM0) = aM_accM0 in
    (1 + (bn_v n % pow2 64) * v mu) % pow2 64 == 0 /\
    bn_v n % 2 = 1 /\ 1 < bn_v n /\ bn_v n < pow2 (64 * nLen) /\
    0 < bn_v b /\ bn_v b < pow2 bBits /\
    bn_v aM0 < 2 * bn_v n /\ bn_v accM0 < 2 * bn_v n))
  (ensures
   (let (aM0, accM0) = aM_accM0 in
    let (aM1, accM1) = bn_mod_exp_f #nLen #rLen n mu bBits bLen b i aM_accM0 in
    let (aM2, accM2) = BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b) i (bn_v aM0, bn_v accM0) in
    bn_v aM1 == aM2 /\ bn_v accM1 == accM2 /\
    bn_v aM1 < 2 * bn_v n /\ bn_v accM1 < 2 * bn_v n))

let bn_mod_exp_f_lemma #nLen #rLen n mu bBits bLen b i (aM0, accM0) =
  let (aM1, accM1) = bn_mod_exp_f #nLen #rLen n mu bBits bLen b i (aM0, accM0) in
  let (aM2, accM2) = BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b) i (bn_v aM0, bn_v accM0) in
  mont_mul_lemma #nLen #rLen n mu aM0 aM0;
  assert (bn_v aM1 == aM2);
  bn_is_bit_set_lemma #bLen b i;
  if (bn_v b / pow2 i % 2 = 1) then mont_mul_lemma #nLen #rLen n mu aM0 accM0;
  assert (bn_v accM1 == accM2);
  let d, k = M.eea_pow2_odd (64 * rLen) (bn_v n) in
  M.mont_preconditions nLen (bn_v n) (v mu);
  BL.mod_exp_mont_ll_lemma_fits_loop_step rLen (bn_v n) d (v mu) bBits (bn_v b) i (bn_v aM0) (bn_v accM0)


val bn_mod_exp_mont_loop_lemma:
    #nLen:size_nat
  -> #rLen:size_nat{rLen = nLen + 1 /\ rLen + rLen <= max_size_t}
  -> n:lbignum nLen
  -> mu:uint64
  -> bBits:size_pos
  -> bLen:size_nat{bLen == blocks bBits 64}
  -> b:lbignum bLen
  -> i:size_nat{i <= bBits}
  -> aM_accM0: tuple2 (lbignum rLen) (lbignum rLen) -> Lemma
  (requires
   (let (aM0, accM0) = aM_accM0 in
    (1 + (bn_v n % pow2 64) * v mu) % pow2 64 == 0 /\
    bn_v n % 2 = 1 /\ 1 < bn_v n /\ bn_v n < pow2 (64 * nLen) /\
    0 < bn_v b /\ bn_v b < pow2 bBits /\
    bn_v aM0 < 2 * bn_v n /\ bn_v accM0 < 2 * bn_v n))
  (ensures
   (let (aM0, accM0) = aM_accM0 in
    let (aM1, accM1) = repeati i (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0) in
    let (aM2, accM2) = repeati i (BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b)) (bn_v aM0, bn_v accM0) in
    bn_v aM1 == aM2 /\ bn_v accM1 == accM2 /\
    bn_v aM1 < 2 * bn_v n /\ bn_v accM1 < 2 * bn_v n))

let rec bn_mod_exp_mont_loop_lemma #nLen #rLen n mu bBits bLen b i (aM0, accM0) =
  let (aM1, accM1) = repeati i (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0) in
  let (aM2, accM2) = repeati i (BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b)) (bn_v aM0, bn_v accM0) in

  if i = 0 then begin
    eq_repeati0 i (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0);
    eq_repeati0 i (BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b)) (bn_v aM0, bn_v accM0);
    () end
  else begin
    unfold_repeati i (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0) (i - 1);
    unfold_repeati i (BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b)) (bn_v aM0, bn_v accM0) (i - 1);
    let (aM3, accM3) = repeati (i - 1) (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0) in
    let (aM4, accM4) = repeati (i - 1) (BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b)) (bn_v aM0, bn_v accM0) in
    assert ((aM1, accM1) == bn_mod_exp_f #nLen #rLen n mu bBits bLen b (i - 1) (aM3, accM3));
    assert ((aM2, accM2) == BL.mod_exp_f_ll rLen (bn_v n) (v mu) bBits (bn_v b) (i - 1) (aM4, accM4));
    bn_mod_exp_mont_loop_lemma #nLen #rLen n mu bBits bLen b (i - 1) (aM0, accM0);
    assert (bn_v aM3 == aM4 /\ bn_v accM3 == accM4);
    bn_mod_exp_f_lemma #nLen #rLen n mu bBits bLen b (i - 1) (aM3, accM3);
    () end


val lemma_acc_init: nLen:size_pos -> Lemma
  (let acc = create nLen (u64 0) in
   let acc = acc.[0] <- u64 1 in
   bn_v acc == 1)

let lemma_acc_init nLen =
  let acc = create nLen (u64 0) in
  let acc = acc.[0] <- u64 1 in
  bn_eval_split_i acc 1;
  assert (bn_v acc == bn_v (slice acc 0 1) + pow2 64 * bn_v (slice acc 1 nLen));
  eq_intro (slice acc 1 nLen) (create (nLen - 1) (u64 0));
  bn_eval_zeroes (nLen - 1) (nLen - 1);
  assert (bn_v acc == bn_v (slice acc 0 1));
  bn_eval_unfold_i (slice acc 0 1) 1;
  bn_eval0 (slice acc 0 1)


val bn_mod_exp_mont_lemma_aux:
    modBits:size_pos
  -> nLen:size_pos{nLen = (blocks modBits 64) /\ 128 * (nLen + 1) <= max_size_t}
  -> n:lbignum nLen
  -> r2:lbignum nLen
  -> a:lbignum nLen
  -> bBits:size_pos
  -> b:lbignum (blocks bBits 64) -> Lemma
  (requires
   (bn_v n % 2 = 1 /\ 1 < bn_v n /\ bn_v n < pow2 (64 * nLen) /\
    0 < bn_v b /\ bn_v b < pow2 bBits /\ bn_v a < bn_v n /\
    bn_v r2 == pow2 (128 * (nLen + 1)) % bn_v n))
  (ensures
   (let mu = mod_inv_u64 n.[0] in
    let res1 = bn_mod_exp modBits nLen n r2 a bBits b in
    let res2 = BL.mod_exp_mont_ll (nLen + 1) (bn_v n) (v mu) (bn_v a) bBits (bn_v b) in
    bn_v res1 == res2 /\ bn_v res1 < bn_v n))

let bn_mod_exp_mont_lemma_aux modBits nLen n r2 a bBits b =
  let rLen = nLen + 1 in
  let bLen = blocks bBits 64 in

  let acc = create nLen (u64 0) in
  let acc = acc.[0] <- u64 1 in
  lemma_acc_init nLen;
  assert (bn_v acc == 1);

  let mu = mod_inv_u64 n.[0] in
  bn_eval_index n 0;
  assert (bn_v n % pow2 64 == v n.[0]);
  Math.Lemmas.pow2_modulo_modulo_lemma_1 (bn_v n) 2 64;
  assert (v n.[0] % 2 = 1); // since bn_v n % 2 = 1
  mod_inv_u64_lemma n.[0];

  let aM0 = to_mont #nLen #rLen n mu r2 a in
  to_mont_lemma #nLen #rLen n mu r2 a;

  let accM0 = to_mont #nLen #rLen n mu r2 acc in
  to_mont_lemma #nLen #rLen n mu r2 acc;

  let (aM1, accM1) = repeati bBits (bn_mod_exp_f #nLen #rLen n mu bBits bLen b) (aM0, accM0) in
  bn_mod_exp_mont_loop_lemma #nLen #rLen n mu bBits bLen b bBits (aM0, accM0);

  let res = from_mont n mu accM1 in
  from_mont_lemma #nLen #rLen n mu accM1;
  assert (bn_v res <= bn_v n);
  bn_sub_mask_lemma n res


let bn_mod_exp_lemma modBits nLen n r2 a bBits b =
  let mu = mod_inv_u64 n.[0] in
  let res1 = bn_mod_exp modBits nLen n r2 a bBits b in
  let res2 = BL.mod_exp_mont_ll (nLen + 1) (bn_v n) (v mu) (bn_v a) bBits (bn_v b) in
  bn_mod_exp_mont_lemma_aux modBits nLen n r2 a bBits b;
  assert (bn_v res1 == res2 /\ bn_v res1 < bn_v n);

  bn_eval_index n 0;
  assert (bn_v n % pow2 64 == v n.[0]);
  Math.Lemmas.pow2_modulo_modulo_lemma_1 (bn_v n) 2 64;
  assert (v n.[0] % 2 = 1); // since bn_v n % 2 = 1
  mod_inv_u64_lemma n.[0];
  assert ((1 + (bn_v n % pow2 64) * v mu) % pow2 64 == 0);

  let d, k = M.eea_pow2_odd (64 * (nLen + 1)) (bn_v n) in
  M.mont_preconditions nLen (bn_v n) (v mu);
  BL.mod_exp_mont_ll_lemma (nLen + 1) (bn_v n) d (v mu) (bn_v a) bBits (bn_v b)
