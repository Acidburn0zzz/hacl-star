module Lib.Vec.Lemmas

open FStar.Mul
open Lib.IntTypes
open Lib.Sequence


let rec lemma_repeat_gen_vec w n a a_vec normalize_v f f_v acc_v0 =
  let lp = Loops.repeat_right 0 n a_vec f_v acc_v0 in
  let rp = Loops.repeat_right 0 (w * n) a f (normalize_v 0 acc_v0) in
  if n = 0 then begin
    Loops.eq_repeat_right 0 n a_vec f_v acc_v0;
    Loops.eq_repeat_right 0 (w * n) a f (normalize_v 0 acc_v0);
    () end
  else begin
    lemma_repeat_gen_vec w (n - 1) a a_vec normalize_v f f_v acc_v0;
    let next_p = Loops.repeat_right 0 (n - 1) a_vec f_v acc_v0 in
    let next_v = Loops.repeat_right 0 (w * (n - 1)) a f (normalize_v 0 acc_v0) in
    assert (normalize_v (n - 1) next_p == next_v);
    Loops.unfold_repeat_right 0 n a_vec f_v acc_v0 (n - 1);
    assert (lp == f_v (n - 1) next_p);
    Loops.repeat_right_plus 0 (w * (n - 1)) (w * n) a f (normalize_v 0 acc_v0);
    assert (rp == Loops.repeat_right (w * (n - 1)) (w * n) a f next_v);
    assert (normalize_v n lp == Loops.repeat_right (w * (n - 1)) (w * n) a f next_v);
    () end


let lemma_repeati_vec #a #a_vec w n normalize_v f f_v acc_v0 =
  lemma_repeat_gen_vec w n (Loops.fixed_a a) (Loops.fixed_a a_vec) (Loops.fixed_i normalize_v) f f_v acc_v0;
  Loops.repeati_def n f_v acc_v0;
  Loops.repeati_def (w * n) f (normalize_v acc_v0)


let lemma_repeat_gen_blocks_multi_vec #inp_t w blocksize n inp a a_vec f f_v normalize_v acc_v0 = admit()



(*)


////////////////////////
// Start of proof of lemma_repeat_blocks_multi_vec
////////////////////////

val len_div_bs_w: w:pos -> blocksize:pos -> len:nat -> Lemma
  (requires len % (w * blocksize) = 0 /\ len % blocksize = 0)
  (ensures  len / blocksize == len / (w * blocksize) * w)

let len_div_bs_w w blocksize len =
  let blocksize_v = w * blocksize in
  calc (==) {
    len / blocksize;
    (==) { Math.Lemmas.lemma_div_exact len blocksize_v }
    (len / blocksize_v * blocksize_v) / blocksize;
    (==) { Math.Lemmas.paren_mul_right (len / blocksize_v) w blocksize }
    ((len / blocksize_v * w) * blocksize) / blocksize;
    (==) { Math.Lemmas.multiple_division_lemma (len / blocksize_v * w) blocksize }
    len / blocksize_v * w;
  }


val slice_slice_lemma:
    #a:Type0
  -> w:size_pos
  -> blocksize:size_pos{w * blocksize <= max_size_t}
  -> inp:seq a//{length inp % (w * blocksize) = 0 /\ length inp % blocksize = 0}
  -> i:nat{i < length inp / (w * blocksize)}
  -> j:nat{j < w} -> Lemma
  (requires
   (let blocksize_v = w * blocksize in
    let len = length inp in
    let nb_v = len / blocksize_v in
    (i + 1) * blocksize_v <= nb_v * blocksize_v /\
    j * blocksize + blocksize <= blocksize_v /\
    (w * i + j) * blocksize + blocksize <= len))
  (ensures
  (let blocksize_v = w * blocksize in
   let block = Seq.slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) in
   let b1 = Seq.slice block (j * blocksize) (j * blocksize + blocksize) in
   let b2 = Seq.slice inp ((w * i + j) * blocksize) ((w * i + j) * blocksize + blocksize) in
   b1 == b2))

let slice_slice_lemma #a w blocksize inp i j =
  let blocksize_v = w * blocksize in
  Seq.Properties.slice_slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) (j * blocksize) (j * blocksize + blocksize)


val repeat_blocks_multi_vec_step2:
    #a:Type0
  -> #b:Type0
  -> w:size_pos
  -> blocksize:size_pos{w * blocksize <= max_size_t}
  -> inp:seq a{length inp % (w * blocksize) = 0 /\ length inp % blocksize = 0}
  -> f:(lseq a blocksize -> b -> b)
  -> i:nat{i < length inp / (w * blocksize)}
  -> j:nat{j < w}
  -> acc:b -> Lemma
  (let len = length inp in
   let blocksize_v = w * blocksize in
   let nb_v = len / blocksize_v in
   let nb = len / blocksize in
   len_div_bs_w w blocksize len;
   assert (nb == w * nb_v);

   let repeat_bf_s = repeat_blocks_f blocksize inp f nb in
   Math.Lemmas.lemma_mult_le_right blocksize_v (i + 1) nb_v;
   assert ((i + 1) * blocksize_v <= nb_v * blocksize_v);
   let block = Seq.slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) in
   Math.Lemmas.cancel_mul_mod w blocksize;
   let repeat_bf_s1 = repeat_blocks_f blocksize block f w in
   Math.Lemmas.lemma_mult_le_left w (i + 1) nb_v;
   repeat_bf_s1 j acc == repeat_bf_s (w * i + j) acc)

let repeat_blocks_multi_vec_step2 #a #b w blocksize inp f i j acc =
  let len = length inp in
  let blocksize_v = w * blocksize in
  let nb_v = len / blocksize_v in
  let nb = len / blocksize in
  len_div_bs_w w blocksize len;
  assert (nb == w * nb_v);

  Math.Lemmas.lemma_mult_le_right blocksize_v (i + 1) nb_v;
  assert ((i + 1) * blocksize_v <= nb_v * blocksize_v);

  Math.Lemmas.lemma_mult_le_right blocksize (j + 1) w;
  assert (j * blocksize + blocksize <= blocksize_v);

  assert ((w * i + j) * blocksize + blocksize <= len);
  slice_slice_lemma #a w blocksize inp i j


val repeat_blocks_multi_vec_step1:
    #a:Type0
  -> #b:Type0
  -> w:size_pos
  -> blocksize:size_pos{w * blocksize <= max_size_t}
  -> inp:seq a{length inp % (w * blocksize) = 0 /\ length inp % blocksize = 0}
  -> f:(lseq a blocksize -> b -> b)
  -> i:nat{i < length inp / (w * blocksize)}
  -> acc:b -> Lemma
  (let len = length inp in
   let blocksize_v = w * blocksize in
   let nb_v = len / blocksize_v in
   let nb = len / blocksize in
   len_div_bs_w w blocksize len;
   assert (nb == w * nb_v);

   let repeat_bf_s = repeat_blocks_f blocksize inp f nb in
   Math.Lemmas.lemma_mult_le_right blocksize_v (i + 1) nb_v;
   assert ((i + 1) * blocksize_v <= nb_v * blocksize_v);
   let block = Seq.slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) in
   FStar.Math.Lemmas.cancel_mul_mod w blocksize;
   let repeat_bf_s1 = repeat_blocks_f blocksize block f w in
   assert (w * (i + 1) <= w * nb_v);
   let lp = Loops.repeat_right 0 w (Loops.fixed_a b) repeat_bf_s1 acc in
   let rp = Loops.repeat_right (w * i) (w * (i + 1)) (Loops.fixed_a b) repeat_bf_s acc in
   lp == rp)

let repeat_blocks_multi_vec_step1 #a #b w blocksize inp f i acc =
  let len = length inp in
  let blocksize_v = w * blocksize in
  let nb_v = len / blocksize_v in
  let nb = len / blocksize in
  len_div_bs_w w blocksize len;
  assert (nb == w * nb_v);

  let repeat_bf_s = repeat_blocks_f blocksize inp f nb in
  Math.Lemmas.lemma_mult_le_right blocksize_v (i + 1) nb_v;
  assert ((i + 1) * blocksize_v <= nb_v * blocksize_v);
  let block = Seq.slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) in
  FStar.Math.Lemmas.cancel_mul_mod w blocksize;
  let repeat_bf_s1 = repeat_blocks_f blocksize block f w in

  Classical.forall_intro_2 (repeat_blocks_multi_vec_step2 #a #b w blocksize inp f i);
  repeati_right_extensionality w (w * i) (w * (i + 1)) repeat_bf_s1 repeat_bf_s acc


val repeat_blocks_multi_vec_step:
    #a:Type0
  -> #b:Type0
  -> #b_vec:Type0
  -> w:size_pos
  -> blocksize:size_pos{w * blocksize <= max_size_t}
  -> inp:seq a{length inp % (w * blocksize) = 0 /\ length inp % blocksize = 0}
  -> f:(lseq a blocksize -> b -> b)
  -> f_v:(lseq a (w * blocksize) -> b_vec -> b_vec)
  -> normalize_v:(b_vec -> b)
  -> pre:squash (forall (b_v:lseq a (w * blocksize)) (acc_v:b_vec).
      repeat_blocks_multi_vec_equiv_pre w blocksize (w * blocksize) f f_v normalize_v b_v acc_v)
  -> i:nat{i < length inp / (w * blocksize)}
  -> acc_v:b_vec -> Lemma
  (let len = length inp in
   let blocksize_v = w * blocksize in
   let nb_v = len / blocksize_v in
   let nb = len / blocksize in
   len_div_bs_w w blocksize len;
   assert (nb == w * nb_v);

   let repeat_bf_v = repeat_blocks_f blocksize_v inp f_v nb_v in
   let repeat_bf_s = repeat_blocks_f blocksize inp f nb in

   normalize_v (repeat_bf_v i acc_v) ==
   Loops.repeat_right (w * i) (w * (i + 1)) (Loops.fixed_a b) repeat_bf_s (normalize_v acc_v))

let repeat_blocks_multi_vec_step #a #b #b_vec w blocksize inp f f_v normalize_v pre i acc_v =
  let len = length inp in
  let blocksize_v = w * blocksize in
  let nb_v = len / blocksize_v in
  let nb = len / blocksize in
  len_div_bs_w w blocksize len;
  assert (nb == w * nb_v);

  let repeat_bf_v = repeat_blocks_f blocksize_v inp f_v nb_v in
  let repeat_bf_s = repeat_blocks_f blocksize inp f nb in

  Math.Lemmas.lemma_mult_le_right blocksize_v (i + 1) nb_v;
  assert ((i + 1) * blocksize_v <= nb_v * blocksize_v);
  let block = Seq.slice inp (i * blocksize_v) (i * blocksize_v + blocksize_v) in
  Math.Lemmas.cancel_mul_mod w blocksize;
  let repeat_bf_s1 = repeat_blocks_f blocksize block f w in
  let acc = normalize_v acc_v in

  assert (repeat_blocks_multi_vec_equiv_pre w blocksize blocksize_v f f_v normalize_v block acc_v);
  assert (normalize_v (repeat_bf_v i acc_v) == repeat_blocks_multi blocksize block f acc);
  lemma_repeat_blocks_multi blocksize block f acc;
  assert (normalize_v (repeat_bf_v i acc_v) == Loops.repeati w repeat_bf_s1 acc);
  Loops.repeati_def w repeat_bf_s1 acc;
  repeat_blocks_multi_vec_step1 #a #b w blocksize inp f i acc


let lemma_repeat_blocks_multi_vec #a #b #b_vec w blocksize inp f f_v normalize_v acc_v0 =
  let len = length inp in
  let blocksize_v = w * blocksize in
  let nb_v = len / blocksize_v in
  let nb = len / blocksize in
  len_div_bs_w w blocksize len;
  assert (nb == w * nb_v);

  let repeat_bf_v = repeat_blocks_f blocksize_v inp f_v nb_v in
  let repeat_bf_s = repeat_blocks_f blocksize inp f nb in

  calc (==) {
    normalize_v (repeat_blocks_multi blocksize_v inp f_v acc_v0);
    (==) { lemma_repeat_blocks_multi blocksize_v inp f_v acc_v0 }
    normalize_v (Loops.repeati nb_v repeat_bf_v acc_v0);
    (==) { Classical.forall_intro_2 (repeat_blocks_multi_vec_step w blocksize inp f f_v normalize_v ());
      lemma_repeati_vec w nb_v normalize_v repeat_bf_s repeat_bf_v acc_v0}
    Loops.repeati nb repeat_bf_s (normalize_v acc_v0);
    (==) { lemma_repeat_blocks_multi blocksize inp f (normalize_v acc_v0) }
    repeat_blocks_multi blocksize inp f (normalize_v acc_v0);
  }

////////////////////////
// End of proof of lemma_repeat_blocks_multi_vec
////////////////////////
