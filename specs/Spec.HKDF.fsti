module Spec.HKDF

open FStar.Mul

open Spec.Hash.Definitions

val extract:
  a: hash_alg ->
  key: bytes{ Spec.HMAC.keysized a (Seq.length key) } ->
  data: bytes{ Seq.length data + block_length a <= Lib.IntTypes.max_size_t } ->
  Tot (Lib.ByteSequence.lbytes (hash_length a))

val expand:
  a: hash_alg ->
  prk: bytes { HMAC.keysized a (Seq.length prk) } ->
  info: bytes { hash_length a + Seq.length info + 1 + block_length a <= Lib.IntTypes.max_size_t } ->
  required: nat { required <= 255 * hash_length a } ->
  Tot (Lib.ByteSequence.lbytes required)
