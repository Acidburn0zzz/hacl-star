module X64.Stack_i

open X64.Machine_s
open X64.Memory
open Prop_s

val stack: Type u#0

val valid_src_stack64 : ptr:int -> h:stack -> GTot bool
val load_stack64 : ptr:int -> h:stack -> GTot nat64
val store_stack64 : ptr:int -> v:nat64 -> h:stack -> GTot stack
val free_stack64 : start:int -> finish:int -> h:stack -> GTot stack

val valid_src_stack128 : ptr:int -> h:stack -> GTot bool
val load_stack128 : ptr:int -> h:stack -> GTot quad32
val store_stack128 : ptr:int -> v:quad32 -> h:stack -> GTot stack

val init_rsp: h:stack -> (n:nat64{n >= 4096})

let modifies_stack (lo_rsp hi_rsp:nat) (h h':stack) : Prop_s.prop0 =
  forall addr . {:pattern (load_stack64 addr h') \/ (valid_src_stack64 addr h') }
    valid_src_stack64 addr h /\ (addr + 8 <= lo_rsp || addr >= hi_rsp) ==>
      valid_src_stack64 addr h' /\ 
      load_stack64 addr h == load_stack64 addr h'

let valid_src_stack64s (base num_slots:nat) (h:stack) : Prop_s.prop0 =
  forall addr . {:pattern (valid_src_stack64 addr h)}
    (base <= addr) && (addr < base + num_slots `op_Multiply` 8) && (addr - base) % 8 = 0 ==>
      valid_src_stack64 addr h

(* Validity preservation *)

val lemma_store_stack_same_valid64: (ptr:int) -> (v:nat64) -> (h:stack) -> (i:int) -> Lemma
  (requires valid_src_stack64 i h /\
    (i >= ptr + 8 \/ i + 8 <= ptr))
  (ensures valid_src_stack64 i (store_stack64 ptr v h))
  [SMTPat (valid_src_stack64 i (store_stack64 ptr v h))]

val lemma_free_stack_same_valid64: (start:int) -> (finish:int) -> (ptr:int) -> (h:stack) -> Lemma
  (requires valid_src_stack64 ptr h /\
    (ptr >= finish \/ ptr + 8 <= start))
  (ensures valid_src_stack64 ptr (free_stack64 start finish h))
  [SMTPat (valid_src_stack64 ptr (free_stack64 start finish h))]

(* Validity update *)

val lemma_store_new_valid64: (ptr:int) -> (v:nat64) -> (h:stack) -> Lemma
  (valid_src_stack64 ptr (store_stack64 ptr v h))
  [SMTPat (valid_src_stack64 ptr (store_stack64 ptr v h))]

(* Classic select/update lemmas *)
val lemma_correct_store_load_stack64: (ptr:int) -> (v:nat64) -> (h:stack) -> Lemma
  (load_stack64 ptr (store_stack64 ptr v h) == v)
  [SMTPat (load_stack64 ptr (store_stack64 ptr v h))]

val lemma_frame_store_load_stack64: (ptr:int) -> (v:nat64) -> (h:stack) -> (i:int) -> Lemma
  (requires valid_src_stack64 i h /\
    (i >= ptr + 8 \/ i + 8 <= ptr))
  (ensures (load_stack64 i (store_stack64 ptr v h) == load_stack64 i h))
  [SMTPat (load_stack64 i (store_stack64 ptr v h))]

val lemma_free_stack_same_load64: (start:int) -> (finish:int) -> (ptr:int) -> (h:stack) -> Lemma
  (requires valid_src_stack64 ptr h /\
    (ptr >= finish \/ ptr + 8 <= start))
  (ensures load_stack64 ptr h == load_stack64 ptr (free_stack64 start finish h))
  [SMTPat (load_stack64 ptr (free_stack64 start finish h))]

(* Free composition *)
val lemma_compose_free_stack64: (start:int) -> (inter:int) -> (finish:int) -> (h:stack) -> Lemma
  (requires start <= inter /\ inter <= finish)
  (ensures free_stack64 inter finish (free_stack64 start inter h) == free_stack64 start finish h)
  [SMTPat (free_stack64 inter finish (free_stack64 start inter h))]

(* Preservation of the initial stack pointer *)
val lemma_same_init_rsp_free_stack64: (start:int) ->  (finish:int) -> (h:stack) -> Lemma
  (init_rsp (free_stack64 start finish h) == init_rsp h)
  [SMTPat (init_rsp (free_stack64 start finish h))]

val lemma_same_init_rsp_store_stack64: (ptr:int) -> (v:nat64) -> (h:stack) -> Lemma
  (init_rsp (store_stack64 ptr v h) == init_rsp h)
  [SMTPat (init_rsp (store_stack64 ptr v h))]

// Taint for the stack

val valid_taint_stack64: ptr:int -> t:taint -> stackTaint:memtaint -> GTot prop0
val store_taint_stack64: ptr:int -> t:taint -> stackTaint:memtaint -> GTot memtaint

val lemma_valid_taint_stack64: (ptr:int) -> (t:taint) -> (stackTaint:memtaint) -> Lemma
  (requires valid_taint_stack64 ptr t stackTaint)
  (ensures forall i. i >= ptr /\ i < ptr + 8 ==> Map.sel stackTaint i == t)

val lemma_valid_taint_stack64_reveal: (ptr:int) -> (t:taint) -> (stackTaint:memtaint) -> Lemma
  (requires forall i. i >= ptr /\ i < ptr + 8 ==> Map.sel stackTaint i == t)
  (ensures valid_taint_stack64 ptr t stackTaint)

val lemma_correct_store_load_taint_stack64: (ptr:int) -> (t:taint) -> (stackTaint:memtaint) -> Lemma
  (valid_taint_stack64 ptr t (store_taint_stack64 ptr t stackTaint))
  [SMTPat (valid_taint_stack64 ptr t (store_taint_stack64 ptr t stackTaint))]

val lemma_frame_store_load_taint_stack64: (ptr:int) -> (t:taint) -> (stackTaint:memtaint) -> (i:int) -> (t':taint) -> Lemma
  (requires i >= ptr + 8 \/ i + 8 <= ptr)
  (ensures valid_taint_stack64 i t' stackTaint == valid_taint_stack64 i t' (store_taint_stack64 ptr t stackTaint))
  [SMTPat (valid_taint_stack64 i t' (store_taint_stack64 ptr t stackTaint))]


let valid_stack_slot64 (ptr:int) (h:stack) (t:taint) (stackTaint:memtaint) =
  valid_src_stack64 ptr h /\ valid_taint_stack64 ptr t stackTaint

let valid_stack_slot64s (base num_slots:nat) (h:stack) (t:taint) (stackTaint:memtaint) : Prop_s.prop0 =
  forall addr . {:pattern (valid_src_stack64 addr h) \/ (valid_taint_stack64 addr t stackTaint) \/
    (valid_stack_slot64 addr h t stackTaint)}
    (base <= addr) && (addr < base + num_slots `op_Multiply` 8) && (addr - base) % 8 = 0 ==>
      valid_src_stack64 addr h /\ valid_taint_stack64 addr t stackTaint

let modifies_stacktaint (lo_rsp hi_rsp:nat) (h h':memtaint) : Prop_s.prop0 =
  forall addr t. {:pattern (valid_taint_stack64 addr t h') }
    (addr + 8 <= lo_rsp || addr >= hi_rsp) ==>
      valid_taint_stack64 addr t h == valid_taint_stack64 addr t h'
