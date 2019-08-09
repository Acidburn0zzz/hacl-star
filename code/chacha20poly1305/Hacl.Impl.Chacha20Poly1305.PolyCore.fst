module Hacl.Impl.Chacha20Poly1305.PolyCore

module ST = FStar.HyperStack.ST
open FStar.HyperStack
open FStar.HyperStack.All
open Lib.IntTypes
open Lib.Buffer
open Lib.ByteBuffer
open Lib.ByteSequence
module Seq = Lib.Sequence
open FStar.Mul

module SpecPoly = Spec.Poly1305
module Spec = Spec.Chacha20Poly1305
module Poly = Hacl.Impl.Poly1305
module Poly32 = Hacl.Poly1305_32
open Hacl.Impl.Poly1305.Fields

#set-options "--z3rlimit 50 --max_fuel 0 --max_ifuel 0"

let poly1305_padded ctx len text tmp =
  let h_init = ST.get() in
  let n = div len 16ul in
  div_lemma len 16ul;
  let r = mod len 16ul in
  mod_lemma len 16ul;
  let blocks = sub text 0ul (mul n 16ul) in
  mul_lemma n 16ul;
  let rem = sub text (mul n 16ul) r in // the extra part of the input data
  let h0 = ST.get() in
  Poly32.poly1305_update ctx (mul n 16ul) blocks;
  let h1 = ST.get() in
  update_sub tmp 0ul r rem;
  let h2 = ST.get() in
  Poly.reveal_ctx_inv ctx h1 h2;
  if gt r 0ul then   // if r > 0
    Poly32.poly1305_update1 ctx tmp

let poly1305_init ctx k = Poly32.poly1305_init ctx k

let update1 ctx text =
  let h0 = ST.get() in
  Poly32.poly1305_update1 ctx text

let finish ctx k out = Poly32.poly1305_finish out k ctx
