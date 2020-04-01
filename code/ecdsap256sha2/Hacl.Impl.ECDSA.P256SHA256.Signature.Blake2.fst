module Hacl.Impl.ECDSA.P256SHA256.Signature.Blake2

open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes
open Lib.Buffer
open Lib.ByteSequence

open Spec.ECDSA
open Spec.P256.Lemmas

open FStar.Mul
open FStar.Math.Lemmas

open Hacl.Hash.SHA2

open Spec.P256
open Spec.P256.Lemmas
open Spec.P256.Definitions

open Spec.ECDSAP256.Definition

open Hacl.Impl.LowLevel

open Hacl.Impl.P256

open Hacl.Impl.ECDSA.MM.Exponent
open Hacl.Impl.ECDSA.MontgomeryMultiplication

open Hacl.Impl.P256.Signature.Common

module H = Spec.Agile.Hash
module Def = Spec.Hash.Definitions

open Spec.Blake2
open Hacl.Blake2b_32


open Spec.Hash.Definitions
open Hacl.Hash.Definitions

#set-options "--z3rlimit 100 --ifuel  0 --fuel 0"

val ecdsa_signature_step12: mLen: size_t -> m: lbuffer uint8 mLen -> result: felem -> Stack unit
  (requires fun h -> live h m /\ live h result )
  (ensures fun h0 _ h1 -> modifies (loc result) h0 h1 /\
    (
      let hashM = Spec.Blake2.blake2b (as_seq h0 m) 0 Seq.Base.empty 32 in 
      as_nat h1 result = nat_from_bytes_be hashM % prime_p256_order
    )   
  )

  
let ecdsa_signature_step12 mLen m result = 
  push_frame(); 
    let h0 = ST.get() in 
  let mHash = create (size 32) (u8 0) in    
  blake2b (size 32) mHash mLen m (size 0) (null uint8);
  toUint64ChangeEndian mHash result;
  let h1 = ST.get() in 
  reduction_prime_2prime_order result result;

  lemma_core_0 result h1;
  Spec.ECDSA.changeEndianLemma (uints_from_bytes_be #U64 #_ #4 (as_seq h1 mHash));
  uints_from_bytes_be_nat_lemma #U64 #_ #4 (as_seq h1 mHash);

  pop_frame()

#push-options "--ifuel 1"

val ecdsa_signature_step45: x: felem -> k: lbuffer uint8 (size 32) -> tempBuffer: lbuffer uint64 (size 100) -> Stack uint64
  (requires fun h -> 
    live h x /\ live h k /\ live h tempBuffer /\ 
    LowStar.Monotonic.Buffer.all_disjoint [loc tempBuffer; loc k; loc x]
  )
  (ensures fun h0 r h1 -> 
    modifies (loc x |+| loc tempBuffer) h0 h1 /\ 
    as_nat h1 x < prime_p256_order /\ 
    (
      let (rxN, ryN, rzN), _ = montgomery_ladder_spec (as_seq h0 k) ((0,0,0), basePoint) in 
      let (xN, _, _) = _norm (rxN, ryN, rzN) in 
      as_nat h1 x == xN % prime_p256_order /\ 
      (
	if as_nat h1 x = 0 then uint_v r == pow2 64 - 1 else uint_v r == 0
      )
    )
  )

let ecdsa_signature_step45 x k tempBuffer = 
  push_frame();
    let result = create (size 12) (u64 0) in 
    let tempForNorm = sub tempBuffer (size 0) (size 88) in 
    secretToPublicWithoutNorm result k tempBuffer; 
    normX result x tempForNorm;
    reduction_prime_2prime_order x x;
  pop_frame();
    isZero_uint64_CT x

#pop-options

val lemma_power_step6: kInv: nat -> Lemma 
  (Spec.ECDSA.exponent_spec (fromDomain_ kInv) == toDomain_ (pow kInv (prime_p256_order - 2)))

let lemma_power_step6 kInv = 
  let a = Spec.ECDSA.exponent_spec (fromDomain_ kInv) in 
  lemmaFromDomain kInv;

  power_distributivity (kInv * modp_inv2_prime (pow2 256) prime_p256_order) (prime_p256_order - 2) prime_p256_order;
  power_distributivity_2 kInv (modp_inv2_prime (pow2 256) prime_p256_order % prime_p256_order) (prime_p256_order - 2);
  lemma_mod_mul_distr_r (pow kInv (prime_p256_order - 2)) (pow (modp_inv2_prime (pow2 256) prime_p256_order) (prime_p256_order - 2)) prime_p256_order;

  lemma_pow_mod_n_is_fpow prime_p256_order (pow2 256 % prime_p256_order) (prime_p256_order - 2);
  
  let inverse2_256 = 43790243014242295660885426880012836369732278457577312309071968676491870960761 in 
  assert_norm(modp_inv2_prime (pow2 256) prime_p256_order = inverse2_256); 
  lemma_pow_mod_n_is_fpow prime_p256_order inverse2_256 (prime_p256_order - 2);
  assert_norm(exp #prime_p256_order inverse2_256 (prime_p256_order - 2) == pow2 256 % prime_p256_order);

  lemma_mod_mul_distr_r (pow kInv (prime_p256_order - 2)) (pow2 256) prime_p256_order;
  lemmaToDomain (pow kInv (prime_p256_order - 2))


#push-options "--z3rlimit 300 --ifuel 1"

val ecdsa_signature_step6: result: felem -> kFelem: felem -> z: felem -> r: felem -> da: felem -> Stack unit
  (requires fun h -> 
    live h result /\ live h kFelem /\ live h z /\ live h r /\ live h da /\
    as_nat h kFelem < prime_p256_order /\ 
    as_nat h z < prime_p256_order /\ 
    as_nat h r < prime_p256_order /\ 
    as_nat h da < prime_p256_order
  )
  (ensures fun h0 _ h1 -> 
    modifies (loc result) h0 h1 /\
    as_nat h1 result = (as_nat h0 z + as_nat h0 r * as_nat h0 da) * pow (as_nat h0 kFelem) (prime_p256_order - 2) % prime_p256_order
  )

let ecdsa_signature_step6 result kFelem z r da = 
  let open FStar.Tactics in 
  let open FStar.Tactics.Canon in 
  push_frame();
    let rda = create (size 4) (u64 0) in 
    let zBuffer = create (size 4) (u64 0) in 
    let kInv = create (size 4) (u64 0) in 
  let h0 = ST.get() in 
    montgomery_multiplication_ecdsa_module r da rda;
    fromDomainImpl z zBuffer;
    felem_add rda zBuffer zBuffer;  
    copy kInv kFelem;
    montgomery_ladder_exponent kInv;
    montgomery_multiplication_ecdsa_module zBuffer kInv result;
  pop_frame();
      let br0 = as_nat h0 z + as_nat h0 r * as_nat h0 da in
      let br1 = pow (as_nat h0 kFelem) (prime_p256_order - 2) in 
       
      lemmaFromDomain (as_nat h0 r * as_nat h0 da); 
      lemma_felem_add (as_nat h0 r * as_nat h0 da) (as_nat h0 z);
      lemma_power_step6 (as_nat h0 kFelem);

      lemmaFromDomain (fromDomain_ br0);
      lemmaToDomain br1;
      assert_norm ((modp_inv2_prime (pow2 256) prime_p256_order * pow2 256) % prime_p256_order = 1);
       
      lemma_mod_mul_distr_l (fromDomain_ br0 * modp_inv2_prime (pow2 256) prime_p256_order) (br1 * pow2 256 % prime_p256_order) prime_p256_order;
      lemma_mod_mul_distr_r (fromDomain_ br0 * modp_inv2_prime (pow2 256) prime_p256_order) (br1 * pow2 256) prime_p256_order;
       
      assert_by_tactic (fromDomain_ br0 * modp_inv2_prime (pow2 256) prime_p256_order * (br1 * pow2 256) == fromDomain_ br0 * modp_inv2_prime (pow2 256) prime_p256_order * br1 * pow2 256) canon;
      assert_by_tactic (fromDomain_ br0 * br1 * (modp_inv2_prime (pow2 256) prime_p256_order * pow2 256) == fromDomain_ br0 * modp_inv2_prime (pow2 256) prime_p256_order * br1 * pow2 256) canon;
       
      lemma_mod_mul_distr_r (fromDomain_ br0 * br1) (modp_inv2_prime (pow2 256) prime_p256_order * pow2 256) prime_p256_order;
      lemmaToDomain ((fromDomain_ br0 * br1) % prime_p256_order);
      lemmaFromDomain br0;
       
      lemma_mod_mul_distr_l (br0 * modp_inv2_prime (pow2 256) prime_p256_order) br1 prime_p256_order;
      lemma_mod_mul_distr_l (br0 * modp_inv2_prime (pow2 256) prime_p256_order * br1) (pow2 256) prime_p256_order;
       
      assert_by_tactic (br0 * modp_inv2_prime (pow2 256) prime_p256_order * br1 * pow2 256 = br0 * br1 * (modp_inv2_prime (pow2 256) prime_p256_order * pow2 256)) canon;
      lemma_mod_mul_distr_r (br0 * br1) (modp_inv2_prime (pow2 256) prime_p256_order * pow2 256) prime_p256_order;
      lemma_mod_mul_distr_r br0 br1 prime_p256_order


val ecdsa_signature_core: r: felem -> s: felem -> mLen: size_t -> m: lbuffer uint8 mLen ->  
  privKeyAsFelem: felem  -> 
  k: lbuffer uint8 (size 32) -> 
  Stack uint64
  (requires fun h -> 
    live h r /\ live h s /\ live h m /\ live h privKeyAsFelem /\ live h k /\
    disjoint privKeyAsFelem r /\
    disjoint privKeyAsFelem s /\
    disjoint k r /\
    disjoint r s /\   
    as_nat h privKeyAsFelem < prime_p256_order /\
    as_nat h s == 0 /\
    nat_from_bytes_be (as_seq h k) < prime_p256_order
  )
  (ensures fun h0 flag h1 -> 
    modifies (loc r |+| loc s) h0 h1 /\
    (
      let hashM = Spec.Blake2.blake2b (as_seq h0 m) 0 Seq.Base.empty 32  in 
      let z =  nat_from_bytes_be hashM % prime_p256_order in 
      let (rxN, ryN, rzN), _ = montgomery_ladder_spec (as_seq h0 k) ((0,0,0), basePoint) in 
      let (xN, _, _) = _norm (rxN, ryN, rzN) in 
      
      let kFelem = nat_from_bytes_be (as_seq h0 k) in 
      as_nat h1 r == xN % prime_p256_order  /\ 
      as_nat h1 s == (z + (as_nat h1 r) * as_nat h0 privKeyAsFelem) * pow kFelem (prime_p256_order - 2) % prime_p256_order /\
      (
	if as_nat h1 r = 0 || as_nat h1 s = 0 then 
	  uint_v flag == pow2 64 - 1
	else 
	  uint_v flag == 0
      ) 
    )  
  )

let ecdsa_signature_core r s mLen m privKeyAsFelem k = 
  push_frame();
  let h0 = ST.get() in 
    let tempBuffer = create (size 108) (u64 0) in 
       let hashAsFelem = sub tempBuffer (size 0) (size 4) in 
       let signatComputationBuffer = sub tempBuffer (size 4) (size 100) in  
       let kAsFelem = sub tempBuffer (size 104) (size 4) in 
  toUint64ChangeEndian k kAsFelem; 
  ecdsa_signature_step12 mLen m hashAsFelem;
  let h1 = ST.get() in 
      lemma_core_0 kAsFelem h1;
      Spec.ECDSA.changeEndianLemma (uints_from_bytes_be (as_seq h0 k));
      uints_from_bytes_be_nat_lemma #U64 #_ #4 (as_seq h0 k); 
      let step5Flag = ecdsa_signature_step45 r k signatComputationBuffer in 
      ecdsa_signature_step6 s kAsFelem hashAsFelem r privKeyAsFelem;  
  let sIsZero = isZero_uint64_CT s in  
  logor_lemma step5Flag sIsZero;
  pop_frame(); 
  logor step5Flag sIsZero


val ecdsa_signature_blake2: result: lbuffer uint8 (size 64) -> mLen: size_t -> m: lbuffer uint8 mLen ->
  privKey: lbuffer uint8 (size 32) -> 
  k: lbuffer uint8 (size 32) -> 
  Stack uint64
  (requires fun h -> 
    live h result /\ live h m /\ live h privKey /\ live h k /\
    disjoint result m /\
    disjoint result privKey /\
    disjoint result k /\
    nat_from_bytes_be (as_seq h privKey) < prime_p256_order /\
    nat_from_bytes_be (as_seq h k) < prime_p256_order
  )
  (ensures fun h0 flag h1 -> 
    modifies (loc result) h0 h1 /\
     (assert_norm (pow2 32 < pow2 61);
      let resultR = gsub result (size 0) (size 32) in 
      let resultS = gsub result (size 32) (size 32) in 
      let r, s, flagSpec = Spec.ECDSA.ecdsa_signature_blake2 (uint_v mLen) (as_seq h0 m) (as_seq h0 privKey) (as_seq h0 k) in 
      as_seq h1 resultR == nat_to_bytes_be 32 r /\
      as_seq h1 resultS == nat_to_bytes_be 32 s /\
      flag == flagSpec 
    )    
  )


let ecdsa_signature_blake2 result mLen m privKey k = 
  push_frame();
  let h0 = ST.get() in 
  assert_norm (pow2 32 < pow2 61); 
  let privKeyAsFelem = create (size 4) (u64 0) in 
  let r = create (size 4) (u64 0) in 
  let s = create (size 4) (u64 0) in 
  let resultR = sub result (size 0) (size 32) in 
  let resultS = sub result (size 32) (size 32) in 
  toUint64ChangeEndian privKey privKeyAsFelem;

  let h1 = ST.get() in 
  lemma_core_0 privKeyAsFelem h1;
  Spec.ECDSA.changeEndianLemma (uints_from_bytes_be (as_seq h0 privKey));
  uints_from_bytes_be_nat_lemma #U64 #_ #4 (as_seq h1 privKey);    
  let flag = ecdsa_signature_core r s mLen m privKeyAsFelem k in 

  let h2 = ST.get() in 
  
  changeEndian r;
  toUint8 r resultR;
  lemma_core_0 r h2;
  lemma_nat_from_to_intseq_le_preserves_value 4 (as_seq h2 r);

  changeEndian s;
  toUint8 s resultS;
  let h3 = ST.get() in 
  lemma_core_0 s h2;
  lemma_nat_from_to_intseq_le_preserves_value 4 (as_seq h2 s);

  Spec.ECDSA.changeEndian_le_be (as_nat h2 r);
  Spec.ECDSA.changeEndian_le_be (as_nat h2 s);

  pop_frame();
  flag  

#pop-options
