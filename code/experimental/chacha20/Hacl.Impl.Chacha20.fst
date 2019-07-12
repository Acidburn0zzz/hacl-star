module Hacl.Impl.Chacha20

module ST = FStar.HyperStack.ST
open FStar.HyperStack
open FStar.HyperStack.All
open Lib.IntTypes
open Lib.Buffer
open Lib.ByteBuffer

open Hacl.Impl.Chacha20.Core32
module Spec = Spec.Chacha20
module Loop = Lib.LoopCombinators

#set-options "--z3rlimit 100"
#set-options "--debug Hacl.Impl.Curve25519.Generic --debug_level ExtractNorm"

//inline_for_extraction
[@ CInline]
val rounds: st:state -> ST unit
		  (requires (fun h -> live h st))
		  (ensures (fun h0 _ h1 -> modifies (loc st) h0 h1 /\
		    as_seq h1 st == Spec.rounds (as_seq h0 st)))

[@ CInline]
let rounds st =
  let h0 = ST.get () in
  Loop.eq_repeat0 #Spec.state Spec.double_round (as_seq h0 st);
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 0;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 1;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 2;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 3;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 4;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 5;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 6;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 7;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 8;
  Loop.unfold_repeat 10 Spec.double_round (as_seq h0 st) 9;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st;
  double_round st
	  
[@ CInline ]
val chacha20_core: k:state -> ctx0:state -> ctr:size_t -> ST unit
		  (requires (fun h -> live h ctx0 /\ live h k /\ disjoint ctx0 k /\
			       (let s0 = as_seq h ctx0 in
				v (Lib.Sequence.index s0 12) + v ctr <= max_size_t)))
		  (ensures (fun h0 _ h1 -> modifies (loc k) h0 h1 /\
					as_seq h1 k == Spec.chacha20_core (as_seq h0 ctx0) (v ctr)))
[@ CInline ]
let chacha20_core k ctx ctr =
    copy_state k ctx;
    k.(12ul) <- k.(12ul) +. size_to_uint32 ctr;
    rounds k;
    sum_state k ctx;
    k.(12ul) <- k.(12ul) +. size_to_uint32 ctr


val chacha20_constants: b:ilbuffer size_t 4ul{
			recallable b /\
			witnessed b Spec.Chacha20.chacha20_constants}
let chacha20_constants =
  [@ inline_let]
  let l = [Spec.c0;Spec.c1;Spec.c2;Spec.c3] in
  assert_norm(List.Tot.length l == 4);
  createL_global l
  

inline_for_extraction
val chacha20_init: ctx:state -> k:lbuffer uint8 32ul -> n:lbuffer uint8 12ul -> ctr0:size_t -> ST unit
		  (requires (fun h -> live h ctx /\ live h k /\ live h n /\ disjoint ctx k /\ disjoint ctx n /\ as_seq h ctx == Lib.Sequence.create 16 (u32 0)))
		  (ensures (fun h0 _ h1 -> modifies (loc ctx) h0 h1 /\
			   as_seq h1 ctx == Spec.chacha20_init (as_seq h0 k) (as_seq h0 n) (v ctr0)))

#set-options "--z3rlimit 300"
[@ CInline]
let chacha20_init ctx k n ctr =
    let h0 = ST.get() in
    recall_contents chacha20_constants Spec.chacha20_constants;
    update_sub_f h0 ctx 0ul 4ul
      (fun h -> Lib.Sequence.map secret Spec.chacha20_constants)
      (fun b -> mapT 4ul b secret chacha20_constants);
    let h1 = ST.get() in
    update_sub_f h1 ctx 4ul 8ul
      (fun h -> Lib.ByteSequence.uints_from_bytes_le (as_seq h k))
      (fun b -> uints_from_bytes_le b k);
    let h2 = ST.get() in
    ctx.(12ul) <- size_to_uint32 ctr;
    let h3 = ST.get() in
    update_sub_f h3 ctx 13ul 3ul
      (fun h -> Lib.ByteSequence.uints_from_bytes_le (as_seq h n))
      (fun b -> uints_from_bytes_le b n);
    let h4 = ST.get() in  
    assert (as_seq h4 ctx == Spec.setup (as_seq h0 k) (as_seq h0 n) (v ctr) (as_seq h0 ctx));
    ()
    

inline_for_extraction
val chacha20_encrypt_block: ctx:state -> 
			   out:lbuffer uint8 64ul -> 
			   incr:size_t ->
			   text:lbuffer uint8 64ul -> 
			   ST unit
		  (requires (fun h -> 
			    live h ctx /\ 
			    live h text /\ 
			    live h out /\ 
			    disjoint out ctx /\
			    disjoint text ctx /\
			    (let s0 = as_seq h ctx in
			     v (Lib.Sequence.index s0 12) + v incr <= max_size_t)))
		  (ensures (fun h0 _ h1 -> modifies (loc ctx |+| loc out) h0 h1 /\
			      as_seq h1 out == Spec.chacha20_encrypt_block (as_seq h0 ctx) (v incr) (as_seq h0 text)))
[@ CInline ]
let chacha20_encrypt_block ctx out incr text =
    push_frame();
    let k = create 16ul (u32 0) in
    chacha20_core k ctx incr;
    xor_block out k text;
    pop_frame()


inline_for_extraction
val chacha20_encrypt_last: ctx:state -> 
			   len:size_t{v len < 64} ->
			   out:lbuffer uint8 len -> 
			   incr:size_t ->
			   text:lbuffer uint8 len -> 
			   ST unit
		  (requires (fun h -> 
			    live h ctx /\ 
			    live h text /\ 
			    live h out /\ 
			    disjoint out ctx /\
			    disjoint text ctx /\
			    (let s0 = as_seq h ctx in
			     v (Lib.Sequence.index s0 12) + v incr <= max_size_t)))
		  (ensures (fun h0 _ h1 -> modifies (loc ctx |+| loc out) h0 h1 /\
			      as_seq h1 out == Spec.chacha20_encrypt_last (as_seq h0 ctx) (v incr) (v len) (as_seq h0 text)))
[@ CInline ]
let chacha20_encrypt_last ctx len out incr text =
    push_frame();
    let plain = create (size 64) (u8 0) in
    update_sub plain 0ul len text;
    chacha20_encrypt_block ctx plain incr plain;
    copy out (sub plain 0ul len);
    pop_frame()



inline_for_extraction
val chacha20_update: ctx:state -> len:size_t -> out:lbuffer uint8 len -> text:lbuffer uint8 len -> ST unit
		  (requires (fun h -> 
			    live h ctx /\ 
			    live h text /\ 
			    live h out /\ 
			    disjoint text ctx /\
			    disjoint out ctx /\
			    (let s0 = as_seq h ctx in 
			     v (Lib.Sequence.index s0 12) + (v len / 64)  <=  max_size_t)))
		  (ensures (fun h0 _ h1 -> modifies (loc ctx |+| loc out) h0 h1 /\
			      as_seq h1 out == Spec.chacha20_update (as_seq h0 ctx) (as_seq h0 text)))
[@ CInline ]
let chacha20_update ctx len out text =
  push_frame();
  let k = create_state () in
  let blocks = len /. size 64 in
  let h0 = ST.get() in
  loop1 h0 blocks out 
    (fun h -> (fun i bufs -> bufs))
    (fun i -> let ib = sub text (size 64 *. i) (size 64) in
	   let ob = sub out (size 64 *. i) (size 64) in
	   chacha20_encrypt_block ctx ob i ib;
	   admit()
	   );
  let rem = len %. size 64 in
  if (rem >. size 0) then (
    let ib = sub text (size 64 *. blocks) rem in
    let ob = sub out (size 64 *. blocks) rem in
    chacha20_encrypt_last ctx rem ob blocks ib);
  admit();
  pop_frame()



inline_for_extraction
val chacha20_encrypt: len:size_t -> out:lbuffer uint8 len -> text:lbuffer uint8 len -> key:lbuffer uint8 32ul -> n:lbuffer uint8 12ul -> ctr:size_t -> ST unit
		  (requires (fun h -> live h key /\ live h n /\ live h text /\ live h out /\ v ctr + v len / 64 <= max_size_t ))
		  (ensures (fun h0 _ h1 -> modifies (loc out) h0 h1 /\
			      as_seq h1 out == Spec.chacha20_encrypt_bytes (as_seq h0 key) (as_seq h0 n) (v ctr) (as_seq h0 text)))
let chacha20_encrypt len out text key n ctr = 
    push_frame();
    let ctx = create_state () in
    chacha20_init ctx key n ctr;
    chacha20_update ctx len out text;
    pop_frame()



inline_for_extraction
val chacha20_decrypt: len:size_t -> out:lbuffer uint8 len -> cipher:lbuffer uint8 len -> key:lbuffer uint8 32ul -> n:lbuffer uint8 12ul -> ctr:size_t -> ST unit
		  (requires (fun h -> live h key /\ live h n /\ live h cipher /\ live h out /\ v ctr + v len / 64 <= max_size_t ))
		  (ensures (fun h0 _ h1 -> modifies (loc out) h0 h1 /\
			      as_seq h1 out == Spec.chacha20_decrypt_bytes (as_seq h0 key) (as_seq h0 n) (v ctr) (as_seq h0 cipher)))
let chacha20_decrypt len out cipher key n ctr = 
    push_frame();
    let ctx = create_state () in
    chacha20_init ctx key n ctr;
    chacha20_update ctx len out cipher;
    pop_frame()


