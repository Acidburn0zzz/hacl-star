module Spec.RSAPSS

open FStar.Mul
open Lib.IntTypes

open Lib.Sequence
open Lib.ByteSequence
open Lib.LoopCombinators


#reset-options "--z3rlimit 50 --max_fuel 0 --max_ifuel 0"

///
/// Auxillary functions
///

val blocks: x: size_pos -> m: size_pos -> Tot (r:size_pos{x <= m * r})
let blocks x m = (x - 1) / m + 1

val xor_bytes: #len: size_pos -> b1: lbytes len -> b2: lbytes len -> Tot (lbytes len)
let xor_bytes #len b1 b2 = map2 (fun x y -> x ^. y) b1 b2

let hLen = 32
let max_input = Spec.Hash.Definitions.max_input_length Spec.Hash.Definitions.SHA2_256
let sha2_256 (msg:bytes{length msg < max_input}) : lbytes hLen = Spec.Agile.Hash.hash Spec.Hash.Definitions.SHA2_256 msg


(* Mask Generation Function *)
val mgf_sha256_f:
     len: size_nat{len + 4 <= max_size_t /\ len + 4 < max_input}
  -> i:size_nat
  -> mgfseed_counter: lbytes (len + 4) ->
  lbytes (len + 4) & lbytes hLen

let mgf_sha256_f len i mgfseed_counter =
  let counter = nat_to_intseq_be 4 i in
  let mgfseed_counter = update_sub mgfseed_counter len 4 counter in
  let block = sha2_256 mgfseed_counter in
  mgfseed_counter, block

let mgf_sha256_a (len:size_nat{len + 4 <= max_size_t}) (n:pos) (i:nat{i <= n}) = lbytes (len + 4)

val mgf_sha256:
    #len: size_nat{len + 4 <= max_size_t /\ len + 4 < max_input}
  -> mgfseed: lbytes len
  -> maskLen: size_pos{(blocks maskLen hLen) * hLen < pow2 32} ->
  Tot (lbytes maskLen)

let mgf_sha256 #len mgfseed maskLen =
  let mgfseed_counter = create (len + 4) (u8 0) in
  let mgfseed_counter = update_sub mgfseed_counter 0 len mgfseed in

  let n = blocks maskLen hLen in
  let _, acc = generate_blocks #uint8 hLen n n (mgf_sha256_a len n) (mgf_sha256_f len) mgfseed_counter in
  sub #uint8 #(n * hLen) acc 0 maskLen


(* Bignum convert functions *)
val os2ip: #len: size_nat -> b: lbytes len -> Tot (res: nat{res < pow2 (8 * len)})
let os2ip #len b = nat_from_bytes_be b

val i2osp: #len: size_nat -> n: nat{n < pow2 (8 * len)} -> Tot (lbytes len)
let i2osp #len n = nat_to_intseq_be len n

(* Modular arithmetic *)
type elem (n:pos) = x:nat{x < n}

let fmul (#n:pos) (x:elem n) (y:elem n) : elem n = (x * y) % n

val fpow: #n:pos -> a:elem n -> b:pos -> Tot (res:elem n) (decreases b)
let rec fpow #n a b =
  if b = 1 then a
  else
    if b % 2 = 0 then fpow (fmul a a) (b / 2)
    else fmul a (fpow (fmul a a) (b / 2))


///
/// RSA
///

type modBits_t = modBits: size_nat{1 < modBits}

noeq type rsa_pubkey (modBits:modBits_t) =
  | Mk_rsa_pubkey: n:pos{pow2 (modBits - 1) <= n /\ n < pow2 modBits} -> e:pos -> rsa_pubkey modBits

noeq type rsa_privkey (modBits:modBits_t) =
  | Mk_rsa_privkey: pkey:rsa_pubkey modBits -> d:pos -> rsa_privkey modBits

val db_zero: #len: size_pos -> db: lbytes len -> emBits: size_nat ->
  Pure (lbytes len)
  (requires True)
  (ensures fun res ->
    (v res.[0] == (if emBits % 8 > 0 then v db.[0] % pow2 (emBits % 8) else v db.[0])))
let db_zero #len db emBits =
  let msBits = emBits % 8 in
  if msBits > 0 then begin
    let r = db.[0] <- db.[0] &. (u8 0xff >>. size (8 - msBits)) in
    Math.Lemmas.pow2_plus msBits (8 - msBits);
    logand_mask db.[0] (u8 0xff >>. size (8 - msBits)) msBits;
    r end
  else db

val pss_encode:
    #sLen: size_nat{sLen + hLen + 8 <= max_size_t /\ sLen + hLen + 8 < max_input}
  -> #msgLen: size_nat{msgLen < max_input}
  -> salt: lbytes sLen
  -> msg: lbytes msgLen
  -> emBits: size_pos{hLen + sLen + 2 <= blocks emBits 8} ->
  Pure (lbytes (blocks emBits 8))
  (requires True)
  (ensures fun em -> if emBits % 8 > 0 then v em.[0] < pow2 (emBits % 8) else v em.[0] < pow2 8)

let pss_encode #sLen #msgLen salt msg emBits =
  let mHash = sha2_256 msg in

  //m1 = [8 * 0x00; mHash; salt]
  let m1Len = 8 + hLen + sLen in
  let m1 = create m1Len (u8 0) in
  let m1 = update_sub m1 8 hLen mHash in
  let m1 = update_sub m1 (8 + hLen) sLen salt in
  let m1Hash = sha2_256 m1 in

  //db = [0x00;..; 0x00; 0x01; salt]
  let emLen = blocks emBits 8 in
  let dbLen = emLen - hLen - 1 in
  let db = create dbLen (u8 0) in
  let last_before_salt = dbLen - sLen - 1 in
  let db = db.[last_before_salt] <- u8 1 in
  let db = update_sub db (last_before_salt + 1) sLen salt in

  let dbMask = mgf_sha256 m1Hash dbLen in
  let maskedDB = xor_bytes db dbMask in
  let maskedDB = db_zero maskedDB emBits in

  //em = [maskedDB; m1Hash; 0xbc]
  let em = create emLen (u8 0) in
  let em = update_sub em 0 dbLen maskedDB in
  let em = update_sub em dbLen hLen m1Hash in
  assert (v em.[0] == v maskedDB.[0]);
  em.[emLen - 1] <- u8 0xbc


val pss_verify_:
    #msgLen: size_nat{msgLen < max_input}
  -> sLen: size_nat{sLen + hLen + 8 <= max_size_t /\ sLen + hLen + 8 < max_input}
  -> msg: lbytes msgLen
  -> emBits: size_pos {blocks emBits 8 >= sLen + hLen + 2}
  -> em: lbytes (blocks emBits 8) ->
  Tot bool

let pss_verify_ #msgLen sLen msg emBits em =
  let emLen = blocks emBits 8 in
  let dbLen = emLen - hLen - 1 in
  let maskedDB = sub em 0 dbLen in
  let m1Hash = sub em dbLen hLen in

  let dbMask = mgf_sha256 m1Hash dbLen in
  let db = xor_bytes dbMask maskedDB in
  let db = db_zero db emBits in

  let padLen = emLen - sLen - hLen - 1 in
  let pad2 = create padLen (u8 0) in
  let pad2 = pad2.[padLen - 1] <- u8 0x01 in

  let pad  = sub db 0 padLen in
  let salt = sub db padLen sLen in

  if not (lbytes_eq pad pad2) then false
  else begin
    let mHash = sha2_256 msg in
    let m1Len = 8 + hLen + sLen in
    let m1 = create m1Len (u8 0) in
    let m1 = update_sub m1 8 hLen mHash in
    let m1 = update_sub m1 (8 + hLen) sLen salt in
    let m1Hash0 = sha2_256 m1 in
    lbytes_eq m1Hash0 m1Hash
  end


val pss_verify:
    #msgLen: size_nat{msgLen < max_input}
  -> sLen: size_nat{sLen + hLen + 8 <= max_size_t /\ sLen + hLen + 8 < max_input}
  -> msg: lbytes msgLen
  -> emBits: size_pos
  -> em: lbytes (blocks emBits 8) ->
  Tot bool

let pss_verify #msgLen sLen msg emBits em =
  let open Lib.RawIntTypes in
  let emLen = blocks emBits 8 in
  let msBits = emBits % 8 in

  let em_0 = if msBits > 0 then em.[0] &. (u8 0xff <<. size msBits) else u8 0 in
  let em_last = em.[emLen - 1] in

  if (emLen < sLen + hLen + 2) then false
  else begin
    if (not (uint_to_nat #U8 em_last = 0xbc && uint_to_nat #U8 em_0 = 0)) then false
    else pss_verify_ #msgLen sLen msg emBits em end


val os2ip_lemma: emBits:size_pos{hLen + 2 <= blocks emBits 8} -> em:lbytes (blocks emBits 8) -> Lemma
  (requires (if emBits % 8 > 0 then v em.[0] < pow2 (emBits % 8) else v em.[0] < pow2 8))
  (ensures  os2ip #(blocks emBits 8) em < pow2 emBits)
let os2ip_lemma emBits em =
  let emLen = blocks emBits 8 in

  if emBits % 8 > 0 then begin
    nat_from_intseq_be_slice_lemma em 1;
    nat_from_intseq_be_lemma0 (slice em 0 1);
    assert (nat_from_bytes_be em == nat_from_bytes_be (slice em 1 emLen) + pow2 ((emLen - 1) * 8) * v em.[0]);
    assert (nat_from_bytes_be em < pow2 ((emLen - 1) * 8) + pow2 ((emLen - 1) * 8) * v em.[0]);
    calc (<=) {
      pow2 ((emLen - 1) * 8) + pow2 ((emLen - 1) * 8) * v em.[0];
      (==) { Math.Lemmas.distributivity_add_right (pow2 (8 * (emLen - 1))) 1 (v em.[0]) }
      (v em.[0] + 1) * pow2 (8 * (emLen - 1));
      (<=) { Math.Lemmas.lemma_mult_le_right (pow2 (8 * emLen - 1)) (v em.[0] + 1) (pow2 (emBits % 8)) }
      pow2 (emBits % 8) * pow2 (8 * (emLen - 1));
      (==) { Math.Lemmas.pow2_plus (emBits % 8) (8 * (emLen - 1)) }
      pow2 (emBits % 8 + 8 * ((emBits - 1) / 8));
      (==) { Math.Lemmas.euclidean_division_definition (emBits - 1) 8 }
      pow2 (emBits % 8 + (emBits - 1) - (emBits - 1) % 8);
      (<=) { Math.Lemmas.pow2_le_compat emBits (emBits % 8 + (emBits - 1) - (emBits - 1) % 8) }
      pow2 emBits;
    };
   assert (nat_from_bytes_be em < pow2 emBits) end
  else Math.Lemmas.pow2_le_compat emBits (8 * emLen)


val rsapss_sign:
    #sLen: size_nat{sLen + hLen + 8 <= max_size_t /\ sLen + hLen + 8 < max_input}
  -> #msgLen: size_nat{msgLen < max_input}
  -> modBits: modBits_t{sLen + hLen + 2 <= blocks (modBits - 1) 8}
  -> skey: rsa_privkey modBits
  -> salt: lbytes sLen
  -> msg: lbytes msgLen ->
  Tot (lbytes (blocks modBits 8))

let rsapss_sign #sLen #msgLen modBits skey salt msg =
  let pkey = Mk_rsa_privkey?.pkey skey in
  let n = Mk_rsa_pubkey?.n pkey in
  let e = Mk_rsa_pubkey?.e pkey in
  let d = Mk_rsa_privkey?.d skey in

  let nLen = blocks modBits 8 in
  FStar.Math.Lemmas.pow2_le_compat (8 * nLen) modBits;

  let emBits = modBits - 1 in
  let emLen = blocks emBits 8 in

  let em = pss_encode salt msg emBits in
  let m = os2ip #emLen em in
  os2ip_lemma emBits em;
  let s = fpow #n m d in
  i2osp #nLen s


val rsapss_verify:
    #msgLen: size_nat{msgLen < max_input}
  -> modBits: modBits_t
  -> pkey: rsa_pubkey modBits
  -> sLen: size_nat{sLen + hLen + 8 <= max_size_t /\ sLen + hLen + 8 < max_input}
  -> msg: lbytes msgLen
  -> sgnt: lbytes (blocks modBits 8) ->
  Tot bool

let rsapss_verify #msgLen modBits pkey sLen msg sgnt =
  let n = Mk_rsa_pubkey?.n pkey in
  let e = Mk_rsa_pubkey?.e pkey in
  let nLen = blocks modBits 8 in
  FStar.Math.Lemmas.pow2_le_compat (8 * nLen) modBits;

  let emBits = modBits - 1 in
  let emLen = blocks emBits 8 in

  let s = os2ip #nLen sgnt in
  if s < n then begin
    let m = fpow #n s e in
    if m < pow2 (emLen * 8) then
      let em = i2osp #emLen m in
      pss_verify #msgLen sLen msg emBits em
    else false end
  else false
