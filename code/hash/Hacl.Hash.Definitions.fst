module Hacl.Hash.Definitions

module HS = FStar.HyperStack
module ST = FStar.HyperStack.ST

module M = LowStar.Modifies
module B = LowStar.Buffer
module Spec = Spec.Hash.PadFinish
module Blake2 = Hacl.Impl.Blake2.Core

open Lib.IntTypes
open Spec.Hash.Definitions
open FStar.Mul

(** The low-level types that our clients need to be aware of, in order to
    successfully call this module. *)

inline_for_extraction noextract
let impl_word (a:hash_alg) = match a with
  | MD5 | SHA1 | SHA2_224 | SHA2_256 | SHA2_384 | SHA2_512 -> word a
  | Blake2S | Blake2B -> Blake2.element_t (to_blake_alg a) Blake2.M32

inline_for_extraction noextract
let impl_state_length (a:hash_alg) = match a with
  | MD5 | SHA1 | SHA2_224 | SHA2_256 | SHA2_384 | SHA2_512 -> state_word_length a
  | Blake2S | Blake2B -> UInt32.v (4ul *. Blake2.row_len (to_blake_alg a) Blake2.M32)

inline_for_extraction noextract
type state_l (a:hash_alg) = b:B.buffer (impl_word a) { B.length b = impl_state_length a }

inline_for_extraction
type state (a: hash_alg) =
  state_l a & B.pointer (extra_state a)

inline_for_extraction noextract
let invariant (#a: hash_alg) (h:HS.mem) (s:state a) =
  let s, p = s in
  B.live h s /\ B.live h p /\ B.disjoint s p

inline_for_extraction noextract
let footprint (#a:hash_alg) (s:state a) =
   B.loc_buffer (fst s) `B.loc_union` B.loc_buffer (snd s)

inline_for_extraction noextract
let as_seq_l (#a:hash_alg) (h:HS.mem) (s:state_l a) : GTot (words_state' a) =
  match a with
  | MD5 | SHA1 | SHA2_224 | SHA2_256 | SHA2_384 | SHA2_512 -> B.as_seq h s
  | Blake2S -> Blake2.state_v #Spec.Blake2.Blake2S #Blake2.M32 h s
  | Blake2B -> Blake2.state_v #Spec.Blake2.Blake2B #Blake2.M32 h s


inline_for_extraction noextract
let as_seq (#a:hash_alg) (h:HS.mem) (s:state a) : GTot (words_state a) =
  as_seq_l h (fst s), B.deref h (snd s)

inline_for_extraction
let word_len (a: hash_alg): n:size_t { v n = word_length a } =
  match a with
  | MD5 | SHA1 | SHA2_224 | SHA2_256 -> 4ul
  | SHA2_384 | SHA2_512 -> 8ul
  | Blake2S -> 4ul
  | Blake2B -> 8ul

inline_for_extraction
let block_len (a: hash_alg): n:size_t { v n = block_length a } =
  match a with
  | MD5 | SHA1 | SHA2_224 | SHA2_256 -> 64ul
  | SHA2_384 | SHA2_512 -> 128ul
  | Blake2S -> 64ul
  | Blake2B -> 128ul

inline_for_extraction
let hash_word_len (a: hash_alg): n:size_t { v n = hash_word_length a } =
  match a with
  | MD5 -> 4ul
  | SHA1 -> 5ul
  | SHA2_224 -> 7ul
  | SHA2_256 -> 8ul
  | SHA2_384 -> 6ul
  | SHA2_512 -> 8ul
  | Blake2S | Blake2B -> 8ul

inline_for_extraction
let hash_len (a: hash_alg): n:size_t { v n = hash_length a } =
  match a with
  | MD5 -> 16ul
  | SHA1 -> 20ul
  | SHA2_224 -> 28ul
  | SHA2_256 -> 32ul
  | SHA2_384 -> 48ul
  | SHA2_512 -> 64ul
  | Blake2S -> 32ul
  | Blake2B -> 64ul

inline_for_extraction
let blocks_t (a: hash_alg) =
  b:B.buffer uint8 { B.length b % block_length a = 0 }

let hash_t (a: hash_alg) = b:B.buffer uint8 { B.length b = hash_length a }


(** The types of all stateful operations for a hash algorithm. *)

inline_for_extraction
let alloca_st (a: hash_alg) = unit -> ST.StackInline (state a)
  (requires (fun h ->
    HS.is_stack_region (HS.get_tip h)))
  (ensures (fun h0 s h1 ->
    M.(modifies M.loc_none h0 h1) /\
    B.frameOf (fst s) == HS.get_tip h0 /\
    B.frameOf (snd s) == HS.get_tip h0 /\
    invariant h1 s /\
    as_seq h1 s == Spec.Agile.Hash.init a /\
    Map.domain (HS.get_hmap h1) `Set.equal` Map.domain (HS.get_hmap h0) /\
    (HS.get_tip h1) == (HS.get_tip h0) /\
    B.unused_in (fst s) h0 /\ B.unused_in (snd s) h0))

inline_for_extraction
let init_st (a: hash_alg) = s:state a -> ST.Stack unit
  (requires (fun h -> invariant h s))
  (ensures (fun h0 _ h1 ->
    M.(modifies (footprint s) h0 h1) /\
    as_seq h1 s == Spec.Agile.Hash.init a))

inline_for_extraction
let update_st (a: hash_alg) =
  s:state a ->
  block:B.buffer uint8 { B.length block = block_length a } ->
  ST.Stack unit
    (requires (fun h ->
      invariant h s /\ B.live h block /\ B.loc_disjoint (footprint s) (B.loc_buffer block)))
    (ensures (fun h0 _ h1 ->
      M.(modifies (footprint s) h0 h1) /\
      as_seq h1 s == (Spec.Agile.Hash.update a (as_seq h0 s) (B.as_seq h0 block))))

inline_for_extraction
let pad_st (a: hash_alg) = len:len_t a -> dst:B.buffer uint8 ->
  ST.Stack unit
    (requires (fun h ->
      len_v a len <= max_input_length a /\
      B.live h dst /\
      B.length dst = pad_length a (len_v a len)))
    (ensures (fun h0 _ h1 ->
      M.(modifies (loc_buffer dst) h0 h1) /\
      Seq.equal (B.as_seq h1 dst) (Spec.pad a (len_v a len))))

// Note: we cannot take more than 4GB of data because we are currently
// constrained by the size of buffers...
inline_for_extraction
let update_multi_st (a: hash_alg) =
  s:state a ->
  blocks:blocks_t a ->
  n:size_t { B.length blocks = block_length a * v n } ->
  ST.Stack unit
    (requires (fun h ->
      invariant h s /\ B.live h blocks /\ B.loc_disjoint (footprint s) (B.loc_buffer blocks)))
    (ensures (fun h0 _ h1 ->
      B.(modifies (footprint s) h0 h1) /\
      as_seq h1 s == Spec.Agile.Hash.update_multi a (as_seq h0 s) (B.as_seq h0 blocks)))

inline_for_extraction
let update_last_st (a: hash_alg) =
  s:state a ->
  prev_len:len_t a { len_v a prev_len % block_length a = 0 } ->
  input:B.buffer uint8 { B.length input + len_v a prev_len <= max_input_length a } ->
  input_len:size_t { B.length input = v input_len } ->
  ST.Stack unit
    (requires (fun h ->
      invariant h s /\ B.live h input /\ B.loc_disjoint (footprint s) (B.loc_buffer input)))
    (ensures (fun h0 _ h1 ->
      B.(modifies (footprint s) h0 h1) /\
      as_seq h1 s == Spec.Hash.Incremental.update_last a (as_seq h0 s) (len_v a prev_len) (B.as_seq h0 input)))

inline_for_extraction
let finish_st (a: hash_alg) = s:state a -> dst:hash_t a -> ST.Stack unit
  (requires (fun h ->
    invariant h s /\ B.live h dst /\ B.loc_disjoint (footprint s) (B.loc_buffer dst)))
  (ensures (fun h0 _ h1 ->
    M.(modifies (loc_buffer dst) h0 h1) /\
    Seq.equal (B.as_seq h1 dst) (Spec.Hash.PadFinish.finish a (as_seq h0 s))))

inline_for_extraction
let hash_st (a: hash_alg) =
  input:B.buffer uint8 ->
  input_len:size_t { B.length input = v input_len } ->
  dst:hash_t a ->
  ST.Stack unit
    (requires (fun h ->
      B.live h input /\
      B.live h dst /\
      B.disjoint input dst /\
      B.length input <= max_input_length a))
    (ensures (fun h0 _ h1 ->
      B.(modifies (loc_buffer dst) h0 h1) /\
      Seq.equal (B.as_seq h1 dst) (Spec.Agile.Hash.hash a (B.as_seq h0 input))))
