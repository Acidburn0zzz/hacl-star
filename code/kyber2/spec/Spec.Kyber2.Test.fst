module Spec.Kyber2.Test

open FStar.Mul
open FStar.IO
open Lib.IntTypes
open Lib.RawIntTypes
open Lib.Sequence
open Lib.ByteSequence

open Lib.Poly.NTT
open Spec.Kyber2.Indcpa
open Spec.Kyber2.Kem
open Spec.Kyber2.Params

open FStar.All

open FStar.Math.Lemmas
module Seq = Lib.Sequence
friend Lib.IntTypes
  
#reset-options "--max_fuel 0 --max_ifuel 1"

let sharedkeylen = 32

let print_and_compare (#len: size_nat) (test_expected: lbytes len) (test_result: lbytes len)
  : ML bool =
  IO.print_string "\nResult:   ";
  List.iter (fun a -> IO.print_string (UInt8.to_string (u8_to_UInt8 a))) (to_list test_result);
  IO.print_string "\nExpected: ";
  List.iter (fun a -> IO.print_string (UInt8.to_string (u8_to_UInt8 a))) (to_list test_expected);
  for_all2 (fun a b -> uint_to_nat #U8 a = uint_to_nat #U8 b) test_expected test_result

let compare (#len: size_nat) (test_expected: lbytes len) (test_result: lbytes len) =
  for_all2 (fun a b -> uint_to_nat #U8 a = uint_to_nat #U8 b) test_expected test_result

let test_kyber
  (coins: list uint8 {List.Tot.length coins == 32})
  (indcpacoins: list uint8 {List.Tot.length indcpacoins == 32})
  (msgcoins: list uint8 {List.Tot.length msgcoins == 32})
  (ss_expected: list uint8 {List.Tot.length ss_expected == sharedkeylen})
  (pk_expected: list uint8 {List.Tot.length pk_expected == pklen})
  (ct_expected: list uint8 {List.Tot.length ct_expected == ciphertextlen})
  (sk_expected: list uint8 {List.Tot.length sk_expected == sklen})
  : ML bool =
  let coins = createL coins in
  let indcpacoins = createL indcpacoins in
  let msgcoins = createL msgcoins in
  let ss_expected = createL ss_expected in
  let pk_expected = createL pk_expected in
  let ct_expected = createL ct_expected in
  let sk_expected = createL sk_expected in
  match keygen coins indcpacoins with
  |None -> false
  |Some (pk,sk) ->
    (match enc pk msgcoins sharedkeylen with
      |None -> false
      |Some (ct,ss1) -> let ss2 = dec ct sk sharedkeylen in
        let r_pk = compare pk_expected pk in
        let r_sk = compare sk_expected sk in
        let r_ct = compare ct_expected ct in
        let r_ss = print_and_compare ss1 ss2 in
        let r_ss1 = print_and_compare ss_expected ss2 in
        r_pk && r_sk && r_ct && r_ss && r_ss1)

let test1_coins =
  List.Tot.map u8_from_UInt8
    [
      0x3euy; 0x2auy; 0x2euy; 0xa6uy; 0xc9uy; 0xc4uy; 0x76uy; 0xfcuy; 0x49uy; 0x37uy; 0xb0uy; 0x13uy; 0xc9uy; 0x93uy; 0xa7uy; 0x93uy; 0xd6uy; 0xc0uy; 0xabuy; 0x99uy; 0x60uy; 0x69uy; 0x5buy; 0xa8uy; 0x38uy; 0xf6uy; 0x49uy; 0xdauy; 0x53uy; 0x9cuy; 0xa3uy; 0xd0uy
    ]

let test1_indcpacoins =
  List.Tot.map u8_from_UInt8
    [
0x93uy; 0x4duy; 0x60uy; 0xb3uy; 0x56uy; 0x24uy; 0xd7uy; 0x40uy; 0xb3uy; 0x0auy; 0x7fuy; 0x22uy; 0x7auy; 0xf2uy; 0xaeuy; 0x7cuy; 0x67uy; 0x8euy; 0x4euy; 0x04uy; 0xe1uy; 0x3cuy; 0x5fuy; 0x50uy; 0x9euy; 0xaduy; 0xe2uy; 0xb7uy; 0x9auy; 0xeauy; 0x77uy; 0xe2uy
    ]

let test1_msgcoins = List.Tot.map u8_from_UInt8 
  [
    0xbauy; 0xc5uy; 0xbauy; 0x88uy; 0x1duy; 0xd3uy; 0x5cuy; 0x59uy; 0x71uy; 0x96uy; 0x70uy; 0x00uy; 0x46uy; 0x92uy; 0xd6uy; 0x75uy; 0xb8uy; 0x3cuy; 0x98uy; 0xdbuy; 0x6auy; 0x0euy; 0x55uy; 0x80uy; 0x0buy; 0xafuy; 0xebuy; 0x7euy; 0x70uy; 0x49uy; 0x1buy; 0xf4uy
  ]

let test1_pk_expected = List.Tot.map u8_from_UInt8
[
0xf1uy; 0x73uy; 0xbeuy; 0x9duy; 0xc3uy; 0x27uy; 0x39uy; 0x49uy; 0x2auy; 0xbeuy; 0x00uy; 0x32uy; 0x94uy; 0x55uy; 0x92uy; 0x68uy; 0xc5uy; 0xbduy; 0xc3uy; 0xa6uy; 0xb9uy; 0x84uy; 0x2buy; 0x0auy; 0x24uy; 0x81uy; 0x31uy; 0xd9uy; 0xf1uy; 0x2cuy; 0xc4uy; 0x58uy; 0x76uy; 0xefuy; 0xf5uy; 0x39uy; 0x69uy; 0x86uy; 0x5cuy; 0x71uy; 0xc2uy; 0x0auy; 0x9euy; 0xf6uy; 0x52uy; 0xb1uy; 0x3buy; 0x12uy; 0x6duy; 0xf8uy; 0x1duy; 0x79uy; 0x09uy; 0x38uy; 0x62uy; 0xc9uy; 0xceuy; 0x0euy; 0x21uy; 0x9fuy; 0x70uy; 0xa3uy; 0x1auy; 0x98uy; 0x77uy; 0x9cuy; 0xd9uy; 0xacuy; 0x39uy; 0xf1uy; 0xc6uy; 0x72uy; 0xb6uy; 0xb9uy; 0x24uy; 0xe5uy; 0x08uy; 0x97uy; 0xa6uy; 0x9cuy; 0xbauy; 0x4duy; 0x88uy; 0xc1uy; 0x17uy; 0x52uy; 0x0buy; 0x7buy; 0xc3uy; 0x88uy; 0x36uy; 0x2cuy; 0x98uy; 0x9buy; 0xfauy; 0x86uy; 0x1fuy; 0x84uy; 0x72uy; 0x20uy; 0xcauy; 0xcfuy; 0xeeuy; 0x50uy; 0x8cuy; 0x30uy; 0x56uy; 0x91uy; 0x0buy; 0x01uy; 0x18uy; 0xbfuy; 0x50uy; 0x52uy; 0x3cuy; 0x89uy; 0x41uy; 0x01uy; 0xd7uy; 0x8auy; 0x77uy; 0x1buy; 0x0auy; 0x90uy; 0xd7uy; 0x41uy; 0x9cuy; 0x38uy; 0x2fuy; 0x35uy; 0xc8uy; 0x20uy; 0x6fuy; 0x24uy; 0xb8uy; 0x87uy; 0x7buy; 0x37uy; 0xcduy; 0x1auy; 0x30uy; 0x31uy; 0xc2uy; 0x9buy; 0x36uy; 0x45uy; 0xbeuy; 0x3euy; 0xdbuy; 0x8fuy; 0x35uy; 0x1buy; 0x03uy; 0x82uy; 0x26uy; 0x53uy; 0x47uy; 0xa3uy; 0x12uy; 0x2euy; 0x89uy; 0x5buy; 0x45uy; 0x95uy; 0x02uy; 0xcbuy; 0x64uy; 0x9euy; 0x0euy; 0x11uy; 0x7buy; 0x09uy; 0x27uy; 0x23uy; 0xd5uy; 0x18uy; 0x8fuy; 0x4auy; 0x32uy; 0x7auy; 0x55uy; 0x6cuy; 0x03uy; 0xc6uy; 0xa7uy; 0xa2uy; 0x92uy; 0xaauy; 0xb8uy; 0x01uy; 0xe7uy; 0xbauy; 0xbfuy; 0xa8uy; 0x07uy; 0x0buy; 0x2cuy; 0x9fuy; 0x7fuy; 0xbbuy; 0x13uy; 0x08uy; 0x18uy; 0x97uy; 0x31uy; 0x29uy; 0x67uy; 0x4auy; 0xccuy; 0xcfuy; 0x03uy; 0x45uy; 0x0euy; 0xdcuy; 0xf0uy; 0xb4uy; 0xfbuy; 0x19uy; 0xb8uy; 0xc2uy; 0xfcuy; 0xa6uy; 0xb7uy; 0x5buy; 0xc9uy; 0x30uy; 0xd2uy; 0x5euy; 0x30uy; 0x23uy; 0x48uy; 0x33uy; 0xc1uy; 0x9buy; 0x82uy; 0x76uy; 0x30uy; 0x43uy; 0x76uy; 0x62uy; 0xa6uy; 0xe7uy; 0x92uy; 0x38uy; 0x8auy; 0x75uy; 0x01uy; 0xa1uy; 0x55uy; 0x73uy; 0x8auy; 0x2cuy; 0x1auy; 0x68uy; 0xa8uy; 0x83uy; 0x05uy; 0x68uy; 0x01uy; 0x35uy; 0x32uy; 0xb7uy; 0x67uy; 0x84uy; 0x19uy; 0x33uy; 0x73uy; 0x28uy; 0xbauy; 0x97uy; 0xf3uy; 0x07uy; 0x3duy; 0xf5uy; 0xd2uy; 0x76uy; 0x6fuy; 0x84uy; 0x3duy; 0x7euy; 0xe9uy; 0x3fuy; 0x34uy; 0x57uy; 0xa9uy; 0x70uy; 0x50uy; 0x82uy; 0x7euy; 0xecuy; 0x83uy; 0xacuy; 0xa6uy; 0x36uy; 0xaauy; 0xe1uy; 0xa7uy; 0x36uy; 0x01uy; 0xaeuy; 0x25uy; 0x75uy; 0x4auy; 0x95uy; 0xc9uy; 0x3cuy; 0x79uy; 0xc4uy; 0xc8uy; 0x6cuy; 0xb0uy; 0x93uy; 0xcbuy; 0x60uy; 0x73uy; 0xa7uy; 0x68uy; 0x98uy; 0x70uy; 0xb2uy; 0x0auy; 0xfbuy; 0x23uy; 0xb0uy; 0x69uy; 0x57uy; 0x6duy; 0xb6uy; 0x87uy; 0xb4uy; 0xaduy; 0x36uy; 0x01uy; 0x9duy; 0x39uy; 0x59uy; 0x11uy; 0xd6uy; 0x40uy; 0xa7uy; 0x83uy; 0x45uy; 0xf6uy; 0x77uy; 0x0buy; 0x16uy; 0x7buy; 0x08uy; 0xfcuy; 0xccuy; 0xa2uy; 0x94uy; 0xb6uy; 0x5cuy; 0x61uy; 0x5buy; 0xc7uy; 0xbfuy; 0xc2uy; 0xceuy; 0x56uy; 0x28uy; 0xa2uy; 0x3duy; 0x02uy; 0x62uy; 0xbeuy; 0x61uy; 0xb5uy; 0xb1uy; 0x9buy; 0x1auy; 0x94uy; 0xe2uy; 0x18uy; 0x69uy; 0xbbuy; 0x14uy; 0x6euy; 0x1buy; 0x0euy; 0x33uy; 0x00uy; 0xc8uy; 0xffuy; 0x81uy; 0xafuy; 0x9fuy; 0xc5uy; 0xb9uy; 0x67uy; 0x64uy; 0x95uy; 0xd1uy; 0x47uy; 0x84uy; 0xa6uy; 0xfcuy; 0x20uy; 0xf3uy; 0xe2uy; 0x66uy; 0x14uy; 0x6auy; 0x9auy; 0xffuy; 0x72uy; 0xc9uy; 0x27uy; 0x33uy; 0x75uy; 0xf2uy; 0xa3uy; 0x11uy; 0x99uy; 0xf1uy; 0xccuy; 0xd0uy; 0x92uy; 0x46uy; 0xcfuy; 0x86uy; 0xccuy; 0x7auy; 0x4buy; 0x37uy; 0x09uy; 0x2auy; 0x99uy; 0xbfuy; 0x89uy; 0x9buy; 0xb5uy; 0x52uy; 0x7buy; 0xd0uy; 0x36uy; 0x92uy; 0xbduy; 0xb5uy; 0x45uy; 0xbauy; 0x99uy; 0x9cuy; 0x4duy; 0x69uy; 0x2cuy; 0x7cuy; 0xabuy; 0x89uy; 0x74uy; 0x31uy; 0x25uy; 0x30uy; 0x76uy; 0x3cuy; 0x18uy; 0xe0uy; 0x53uy; 0x3fuy; 0xfcuy; 0xc4uy; 0xe0uy; 0xebuy; 0x21uy; 0xe0uy; 0xa4uy; 0xbbuy; 0x1auy; 0xc4uy; 0x9fuy; 0x9cuy; 0xd2uy; 0x07uy; 0xb7uy; 0x64uy; 0x66uy; 0x1buy; 0x9auy; 0x02uy; 0x07uy; 0xbcuy; 0x1euy; 0x87uy; 0x0cuy; 0x14uy; 0x77uy; 0xb3uy; 0x80uy; 0x52uy; 0xb3uy; 0x29uy; 0x50uy; 0x7auy; 0x8buy; 0xe9uy; 0x71uy; 0x84uy; 0x70uy; 0x65uy; 0xacuy; 0xaauy; 0x51uy; 0x23uy; 0x43uy; 0xb5uy; 0x73uy; 0x14uy; 0xbbuy; 0x4duy; 0xdcuy; 0xccuy; 0xb5uy; 0x1fuy; 0x17uy; 0x2euy; 0xf8uy; 0xc7uy; 0x7buy; 0xdauy; 0xb2uy; 0x62uy; 0x7duy; 0xb1uy; 0x9duy; 0x4buy; 0x20uy; 0x3buy; 0x79uy; 0xd0uy; 0x87uy; 0x6duy; 0x70uy; 0x57uy; 0x41uy; 0xb5uy; 0xc2uy; 0xdcuy; 0x42uy; 0x5buy; 0xd0uy; 0x5buy; 0x02uy; 0xf7uy; 0xe7uy; 0x46uy; 0x84uy; 0xd5uy; 0x52uy; 0xf9uy; 0x5cuy; 0x73uy; 0x48uy; 0xc5uy; 0x86uy; 0xaeuy; 0xe5uy; 0x00uy; 0x79uy; 0xe5uy; 0x8buy; 0xc7uy; 0x49uy; 0x8buy; 0x06uy; 0xf1uy; 0x1cuy; 0x91uy; 0xe3uy; 0x30uy; 0x08uy; 0x69uy; 0xcduy; 0x37uy; 0xdcuy; 0xafuy; 0xcfuy; 0xa6uy; 0x5auy; 0x93uy; 0xc0uy; 0xa4uy; 0x58uy; 0xd0uy; 0x43uy; 0x3cuy; 0x0cuy; 0x2euy; 0x6auy; 0x66uy; 0x48uy; 0x14uy; 0x77uy; 0x56uy; 0x07uy; 0x5cuy; 0x04uy; 0x0buy; 0x01uy; 0x49uy; 0x31uy; 0x85uy; 0x67uy; 0x35uy; 0x31uy; 0x46uy; 0xe4uy; 0x87uy; 0x8duy; 0x27uy; 0x72uy; 0xcbuy; 0x6fuy; 0x2auy; 0x00uy; 0xaauy; 0xdauy; 0x5euy; 0xbcuy; 0xecuy; 0x3cuy; 0x4buy; 0x63uy; 0x50uy; 0x79uy; 0x43uy; 0x6euy; 0xdbuy; 0xfbuy; 0x38uy; 0xa9uy; 0xb2uy; 0xc0uy; 0x06uy; 0xc3uy; 0x96uy; 0x09uy; 0xbcuy; 0x6fuy; 0xc6uy; 0xa1uy; 0xa5uy; 0xebuy; 0x05uy; 0x31uy; 0xd6uy; 0x36uy; 0x42uy; 0x91uy; 0x71uy; 0xa4uy; 0x25uy; 0x5auy; 0x6auy; 0x6auy; 0x4cuy; 0xccuy; 0xfduy; 0x47uy; 0x74uy; 0x68uy; 0x81uy; 0xc9uy; 0x63uy; 0x68uy; 0x21uy; 0xe6uy; 0x08uy; 0x60uy; 0xc1uy; 0x09uy; 0x80uy; 0x9cuy; 0x85uy; 0x80uy; 0xd2uy; 0x1buy; 0x59uy; 0x05uy; 0xf7uy; 0x88uy; 0xcbuy; 0x79uy; 0xcduy; 0x85uy; 0xd2uy; 0x37uy; 0xa8uy; 0x63uy; 0xb8uy; 0xaduy; 0xd2uy; 0x0fuy; 0x6auy; 0x18uy; 0xa0uy; 0x39uy; 0xa9uy; 0x6auy; 0xe6uy; 0xe5uy; 0x7fuy; 0xd9uy; 0x33uy; 0x4cuy; 0x5cuy; 0x11uy; 0xa3uy; 0xf8uy; 0x35uy; 0x69uy; 0xdeuy; 0xecuy; 0x26uy; 0x97uy; 0x97uy; 0x8buy; 0xa3uy; 0x0buy; 0x76uy; 0x71uy; 0xc6uy; 0x1euy; 0xcbuy; 0x49uy; 0x19uy; 0x82uy; 0x90uy; 0x4cuy; 0x53uy; 0x24uy; 0x78uy; 0x12uy; 0xa2uy; 0x14uy; 0x0euy; 0x07uy; 0x21uy; 0xdfuy; 0x40uy; 0x2euy; 0xe9uy; 0xaauy; 0x15uy; 0x07uy; 0x91uy; 0x20uy; 0x5auy; 0xe2uy; 0xc6uy; 0x07uy; 0x10uy; 0xa9uy; 0xe7uy; 0xe2uy; 0xa7uy; 0x5auy; 0xaauy; 0x4fuy; 0xabuy; 0xecuy; 0x26uy; 0x83uy; 0x30uy; 0xb0uy; 0x20uy; 0xa5uy; 0xa5uy; 0xb7uy; 0x2fuy; 0x9buy; 0xc8uy; 0x5cuy; 0x0auy; 0x13uy; 0xb9uy; 0xd0uy; 0x41uy; 0x58uy; 0x6fuy; 0xd5uy; 0x83uy; 0xfeuy; 0xb1uy; 0x2auy; 0xfduy; 0x5auy; 0x40uy; 0x2duy; 0xd3uy; 0x3buy; 0x43uy; 0x54uy; 0x3fuy; 0x5fuy; 0xa4uy; 0xebuy; 0x43uy; 0x6cuy; 0x8duy
  ]

let test1_sk_expected = List.Tot.map u8_from_UInt8
  [
0x46uy; 0x23uy; 0x96uy; 0xf6uy; 0xb2uy; 0x1fuy; 0xf6uy; 0x25uy; 0xb9uy; 0x6buy; 0x4buy; 0x1fuy; 0x5cuy; 0x3auy; 0x38uy; 0xb3uy; 0xc8uy; 0x07uy; 0x08uy; 0xf3uy; 0x3buy; 0xccuy; 0x17uy; 0x84uy; 0xbeuy; 0xdbuy; 0x48uy; 0xbeuy; 0xe0uy; 0x25uy; 0x3buy; 0x42uy; 0x6cuy; 0xfbuy; 0x95uy; 0x61uy; 0x87uy; 0x12uy; 0xceuy; 0x98uy; 0x25uy; 0xa5uy; 0x3buy; 0x5cuy; 0xc8uy; 0x7cuy; 0x81uy; 0x43uy; 0xafuy; 0xc4uy; 0x6buy; 0x40uy; 0x62uy; 0x7buy; 0x4cuy; 0x4buy; 0xbduy; 0x2euy; 0x38uy; 0x2cuy; 0xecuy; 0x45uy; 0x7euy; 0x48uy; 0xa7uy; 0x13uy; 0x0cuy; 0x84uy; 0x12uy; 0xc2uy; 0x60uy; 0x5cuy; 0x47uy; 0x59uy; 0x15uy; 0xbfuy; 0x08uy; 0x47uy; 0x6duy; 0xe4uy; 0xb8uy; 0xaauy; 0x70uy; 0x29uy; 0x8auy; 0xb9uy; 0x9duy; 0xefuy; 0x93uy; 0x86uy; 0xc1uy; 0xf1uy; 0x12uy; 0x53uy; 0xc3uy; 0x98uy; 0xc6uy; 0xd0uy; 0xaduy; 0xf9uy; 0xd9uy; 0x7euy; 0x22uy; 0x64uy; 0xa0uy; 0x26uy; 0xe4uy; 0x02uy; 0x11uy; 0xb5uy; 0x9auy; 0x26uy; 0xa2uy; 0x3fuy; 0x16uy; 0x10uy; 0x2auy; 0x22uy; 0x0auy; 0x6fuy; 0x2buy; 0xf2uy; 0x7auy; 0x14uy; 0x01uy; 0x5fuy; 0x6fuy; 0x32uy; 0x61uy; 0xe2uy; 0x74uy; 0x75uy; 0x8cuy; 0xccuy; 0xb7uy; 0x57uy; 0xa4uy; 0x06uy; 0x00uy; 0x53uy; 0x17uy; 0xa0uy; 0x50uy; 0xc2uy; 0x2duy; 0x39uy; 0x9fuy; 0x99uy; 0x49uy; 0x74uy; 0xaauy; 0x73uy; 0x13uy; 0xeduy; 0xfbuy; 0xbauy; 0x46uy; 0x08uy; 0x37uy; 0x16uy; 0x13uy; 0x98uy; 0x54uy; 0x81uy; 0xb0uy; 0xaeuy; 0xc8uy; 0x9euy; 0xdduy; 0x60uy; 0x02uy; 0x75uy; 0x4buy; 0x18uy; 0xe2uy; 0x75uy; 0xb9uy; 0x7auy; 0xf8uy; 0xb4uy; 0xaduy; 0xc6uy; 0x82uy; 0xb5uy; 0x73uy; 0xb9uy; 0xa5uy; 0x68uy; 0x73uy; 0x24uy; 0x23uy; 0xb2uy; 0x0duy; 0xf4uy; 0x18uy; 0xdauy; 0x0auy; 0x0fuy; 0x69uy; 0x08uy; 0x66uy; 0x3buy; 0xe9uy; 0x83uy; 0x3euy; 0xdauy; 0x12uy; 0x69uy; 0x12uy; 0x77uy; 0x02uy; 0xe9uy; 0x7duy; 0xb8uy; 0x2buy; 0xb1uy; 0x1duy; 0xe2uy; 0x2cuy; 0xc0uy; 0x76uy; 0x5euy; 0x26uy; 0xcauy; 0xb6uy; 0x0duy; 0x25uy; 0x6cuy; 0xbbuy; 0x27uy; 0x22uy; 0x13uy; 0x15uy; 0xc2uy; 0xc1uy; 0xd7uy; 0x5fuy; 0x56uy; 0xe6uy; 0xaauy; 0x4cuy; 0x08uy; 0xccuy; 0x83uy; 0x45uy; 0xa1uy; 0x6buy; 0x68uy; 0x00uy; 0xe3uy; 0x30uy; 0x75uy; 0x6cuy; 0xecuy; 0x02uy; 0x67uy; 0xc0uy; 0x2duy; 0x1duy; 0xe1uy; 0xcauy; 0x3cuy; 0xa8uy; 0x73uy; 0x81uy; 0x56uy; 0xc8uy; 0x8euy; 0xd6uy; 0xaeuy; 0x90uy; 0xf8uy; 0x42uy; 0x9buy; 0x5auy; 0xaduy; 0x8cuy; 0x5auy; 0x53uy; 0xfeuy; 0x26uy; 0x87uy; 0xd2uy; 0x07uy; 0x4fuy; 0xdbuy; 0x18uy; 0xb1uy; 0x24uy; 0x1auy; 0x48uy; 0x9euy; 0x85uy; 0x50uy; 0xabuy; 0xaauy; 0x7buy; 0x55uy; 0x9auy; 0xccuy; 0x6auy; 0xb4uy; 0xb5uy; 0x39uy; 0x6cuy; 0x82uy; 0x1buy; 0x85uy; 0x43uy; 0x05uy; 0xcauy; 0xa6uy; 0x6auy; 0x47uy; 0x80uy; 0x39uy; 0xccuy; 0x2cuy; 0xf7uy; 0x36uy; 0x5fuy; 0x56uy; 0xa3uy; 0x44uy; 0xd1uy; 0xf0uy; 0x9auy; 0xa7uy; 0x3auy; 0x66uy; 0x7auy; 0x15uy; 0xceuy; 0x71uy; 0xb2uy; 0x10uy; 0xd9uy; 0xb9uy; 0x30uy; 0x40uy; 0x3auy; 0x38uy; 0xa2uy; 0xa1uy; 0x0cuy; 0xdeuy; 0xf3uy; 0x9buy; 0x9euy; 0x89uy; 0x60uy; 0xaduy; 0x46uy; 0x33uy; 0x13uy; 0xb7uy; 0xabuy; 0x3duy; 0x72uy; 0x3auy; 0x71uy; 0x5cuy; 0x1duy; 0x72uy; 0x9buy; 0x79uy; 0xb4uy; 0x6buy; 0x7buy; 0xceuy; 0xdbuy; 0x31uy; 0xb9uy; 0x2buy; 0x77uy; 0x86uy; 0x4auy; 0xc9uy; 0x14uy; 0x6cuy; 0x15uy; 0xa8uy; 0x9buy; 0xafuy; 0xe1uy; 0x60uy; 0x1fuy; 0xccuy; 0x83uy; 0x28uy; 0xe6uy; 0x57uy; 0xa6uy; 0xebuy; 0xbauy; 0xbeuy; 0xf8uy; 0x11uy; 0x59uy; 0x86uy; 0xdcuy; 0x87uy; 0xf1uy; 0x72uy; 0x34uy; 0xbauy; 0xa3uy; 0x88uy; 0x5euy; 0x33uy; 0xa1uy; 0x85uy; 0x68uy; 0x8buy; 0x91uy; 0x58uy; 0x83uy; 0xecuy; 0x48uy; 0x09uy; 0xc5uy; 0xc9uy; 0x69uy; 0x1buy; 0x95uy; 0xa0uy; 0x81uy; 0x79uy; 0xa4uy; 0x85uy; 0x77uy; 0xc1uy; 0x72uy; 0x4auy; 0xa1uy; 0xbcuy; 0xf6uy; 0x64uy; 0xd5uy; 0xeauy; 0x49uy; 0xc6uy; 0x9auy; 0x72uy; 0x7cuy; 0xdauy; 0x3euy; 0x31uy; 0xe7uy; 0x1euy; 0x67uy; 0x25uy; 0x7euy; 0x65uy; 0xe8uy; 0x47uy; 0xdfuy; 0x59uy; 0x47uy; 0xabuy; 0xe2uy; 0x96uy; 0x75uy; 0x73uy; 0xacuy; 0x2duy; 0x61uy; 0x59uy; 0xf9uy; 0x66uy; 0x99uy; 0xaeuy; 0x16uy; 0xa5uy; 0x5fuy; 0x65uy; 0x4euy; 0x8fuy; 0xe0uy; 0x0buy; 0xeauy; 0x67uy; 0x91uy; 0x13uy; 0x5auy; 0xa0uy; 0x45uy; 0xd8uy; 0x51uy; 0xd0uy; 0xd7uy; 0x3cuy; 0xd1uy; 0x59uy; 0xbeuy; 0x5cuy; 0x00uy; 0x04uy; 0x1buy; 0x10uy; 0x33uy; 0xafuy; 0x18uy; 0x50uy; 0x0cuy; 0xc6uy; 0x2buy; 0x8duy; 0xc6uy; 0x36uy; 0xbeuy; 0xd7uy; 0x0euy; 0x4duy; 0xd4uy; 0x98uy; 0x1euy; 0x37uy; 0x88uy; 0x20uy; 0xebuy; 0x73uy; 0xa7uy; 0xd3uy; 0xbcuy; 0x69uy; 0xa4uy; 0x2duy; 0xcbuy; 0x91uy; 0x03uy; 0xecuy; 0x8buy; 0xb8uy; 0x02uy; 0x07uy; 0x63uy; 0xbauy; 0x76uy; 0xb4uy; 0x82uy; 0x11uy; 0x80uy; 0x65uy; 0x29uy; 0x55uy; 0x3duy; 0xa6uy; 0x48uy; 0x75uy; 0x39uy; 0x89uy; 0x47uy; 0x22uy; 0x44uy; 0x36uy; 0x72uy; 0xbcuy; 0x7euy; 0xc3uy; 0x16uy; 0x46uy; 0x15uy; 0x8cuy; 0xa6uy; 0x63uy; 0x43uy; 0xe2uy; 0xe6uy; 0x9buy; 0xd6uy; 0x38uy; 0xccuy; 0x4auy; 0x3cuy; 0x71uy; 0x1euy; 0x37uy; 0x75uy; 0xceuy; 0x88uy; 0xb4uy; 0x96uy; 0x8auy; 0x2cuy; 0xdbuy; 0xb7uy; 0x72uy; 0xa0uy; 0xd9uy; 0xafuy; 0x6auy; 0xa3uy; 0x91uy; 0x68uy; 0x55uy; 0x00uy; 0x74uy; 0xa6uy; 0x58uy; 0x2duy; 0xa1uy; 0x93uy; 0x66uy; 0xf6uy; 0x1buy; 0xe1uy; 0x74uy; 0x03uy; 0x44uy; 0x72uy; 0x18uy; 0x2duy; 0x90uy; 0x0cuy; 0x05uy; 0x98uy; 0x36uy; 0x9auy; 0x6cuy; 0x65uy; 0x6duy; 0x30uy; 0xc9uy; 0x95uy; 0x57uy; 0xaauy; 0xf6uy; 0xe4uy; 0x30uy; 0x23uy; 0xf4uy; 0x17uy; 0xbcuy; 0x4auy; 0x2duy; 0x8euy; 0x29uy; 0x44uy; 0xc4uy; 0xe6uy; 0x01uy; 0x01uy; 0x52uy; 0xbfuy; 0x28uy; 0xebuy; 0x21uy; 0x19uy; 0xa9uy; 0x04uy; 0x67uy; 0xaauy; 0x18uy; 0x57uy; 0x06uy; 0x39uy; 0x6fuy; 0x93uy; 0x37uy; 0x22uy; 0xf1uy; 0x93uy; 0x73uy; 0xd3uy; 0x43uy; 0x1buy; 0x01uy; 0x7buy; 0x79uy; 0x4auy; 0x19uy; 0xb9uy; 0x8buy; 0x39uy; 0x90uy; 0x18uy; 0x8buy; 0xccuy; 0x71uy; 0x42uy; 0xcduy; 0x23uy; 0xa7uy; 0x5auy; 0x28uy; 0xa9uy; 0x5duy; 0x2cuy; 0x25uy; 0xaauy; 0xf7uy; 0xc2uy; 0xdfuy; 0xd8uy; 0xbauy; 0x06uy; 0xe4uy; 0x70uy; 0x66uy; 0x94uy; 0x0cuy; 0x1fuy; 0xa5uy; 0x56uy; 0x55uy; 0xdauy; 0xb9uy; 0xbeuy; 0xb6uy; 0x86uy; 0x42uy; 0x8cuy; 0x72uy; 0xe9uy; 0x00uy; 0x70uy; 0xf8uy; 0x1auy; 0x6buy; 0xfbuy; 0x63uy; 0x45uy; 0x76uy; 0x61uy; 0x51uy; 0xffuy; 0xc0uy; 0x59uy; 0xeauy; 0x64uy; 0x25uy; 0x5fuy; 0xb2uy; 0x4auy; 0xa3uy; 0xe4uy; 0x7cuy; 0xfcuy; 0x01uy; 0x30uy; 0x0fuy; 0x43uy; 0x91uy; 0x1auy; 0xe3uy; 0x93uy; 0xe6uy; 0xd7uy; 0xa8uy; 0x9euy; 0x1cuy; 0x22uy; 0x8fuy; 0x3buy; 0x55uy; 0xd7uy; 0x0buy; 0x9duy; 0x9duy; 0x4buy; 0x5cuy; 0xc0uy; 0x06uy; 0x71uy; 0xaduy; 0x0buy; 0x69uy; 0xf1uy; 0x73uy; 0xbeuy; 0x9duy; 0xc3uy; 0x27uy; 0x39uy; 0x49uy; 0x2auy; 0xbeuy; 0x00uy; 0x32uy; 0x94uy; 0x55uy; 0x92uy; 0x68uy; 0xc5uy; 0xbduy; 0xc3uy; 0xa6uy; 0xb9uy; 0x84uy; 0x2buy; 0x0auy; 0x24uy; 0x81uy; 0x31uy; 0xd9uy; 0xf1uy; 0x2cuy; 0xc4uy; 0x58uy; 0x76uy; 0xefuy; 0xf5uy; 0x39uy; 0x69uy; 0x86uy; 0x5cuy; 0x71uy; 0xc2uy; 0x0auy; 0x9euy; 0xf6uy; 0x52uy; 0xb1uy; 0x3buy; 0x12uy; 0x6duy; 0xf8uy; 0x1duy; 0x79uy; 0x09uy; 0x38uy; 0x62uy; 0xc9uy; 0xceuy; 0x0euy; 0x21uy; 0x9fuy; 0x70uy; 0xa3uy; 0x1auy; 0x98uy; 0x77uy; 0x9cuy; 0xd9uy; 0xacuy; 0x39uy; 0xf1uy; 0xc6uy; 0x72uy; 0xb6uy; 0xb9uy; 0x24uy; 0xe5uy; 0x08uy; 0x97uy; 0xa6uy; 0x9cuy; 0xbauy; 0x4duy; 0x88uy; 0xc1uy; 0x17uy; 0x52uy; 0x0buy; 0x7buy; 0xc3uy; 0x88uy; 0x36uy; 0x2cuy; 0x98uy; 0x9buy; 0xfauy; 0x86uy; 0x1fuy; 0x84uy; 0x72uy; 0x20uy; 0xcauy; 0xcfuy; 0xeeuy; 0x50uy; 0x8cuy; 0x30uy; 0x56uy; 0x91uy; 0x0buy; 0x01uy; 0x18uy; 0xbfuy; 0x50uy; 0x52uy; 0x3cuy; 0x89uy; 0x41uy; 0x01uy; 0xd7uy; 0x8auy; 0x77uy; 0x1buy; 0x0auy; 0x90uy; 0xd7uy; 0x41uy; 0x9cuy; 0x38uy; 0x2fuy; 0x35uy; 0xc8uy; 0x20uy; 0x6fuy; 0x24uy; 0xb8uy; 0x87uy; 0x7buy; 0x37uy; 0xcduy; 0x1auy; 0x30uy; 0x31uy; 0xc2uy; 0x9buy; 0x36uy; 0x45uy; 0xbeuy; 0x3euy; 0xdbuy; 0x8fuy; 0x35uy; 0x1buy; 0x03uy; 0x82uy; 0x26uy; 0x53uy; 0x47uy; 0xa3uy; 0x12uy; 0x2euy; 0x89uy; 0x5buy; 0x45uy; 0x95uy; 0x02uy; 0xcbuy; 0x64uy; 0x9euy; 0x0euy; 0x11uy; 0x7buy; 0x09uy; 0x27uy; 0x23uy; 0xd5uy; 0x18uy; 0x8fuy; 0x4auy; 0x32uy; 0x7auy; 0x55uy; 0x6cuy; 0x03uy; 0xc6uy; 0xa7uy; 0xa2uy; 0x92uy; 0xaauy; 0xb8uy; 0x01uy; 0xe7uy; 0xbauy; 0xbfuy; 0xa8uy; 0x07uy; 0x0buy; 0x2cuy; 0x9fuy; 0x7fuy; 0xbbuy; 0x13uy; 0x08uy; 0x18uy; 0x97uy; 0x31uy; 0x29uy; 0x67uy; 0x4auy; 0xccuy; 0xcfuy; 0x03uy; 0x45uy; 0x0euy; 0xdcuy; 0xf0uy; 0xb4uy; 0xfbuy; 0x19uy; 0xb8uy; 0xc2uy; 0xfcuy; 0xa6uy; 0xb7uy; 0x5buy; 0xc9uy; 0x30uy; 0xd2uy; 0x5euy; 0x30uy; 0x23uy; 0x48uy; 0x33uy; 0xc1uy; 0x9buy; 0x82uy; 0x76uy; 0x30uy; 0x43uy; 0x76uy; 0x62uy; 0xa6uy; 0xe7uy; 0x92uy; 0x38uy; 0x8auy; 0x75uy; 0x01uy; 0xa1uy; 0x55uy; 0x73uy; 0x8auy; 0x2cuy; 0x1auy; 0x68uy; 0xa8uy; 0x83uy; 0x05uy; 0x68uy; 0x01uy; 0x35uy; 0x32uy; 0xb7uy; 0x67uy; 0x84uy; 0x19uy; 0x33uy; 0x73uy; 0x28uy; 0xbauy; 0x97uy; 0xf3uy; 0x07uy; 0x3duy; 0xf5uy; 0xd2uy; 0x76uy; 0x6fuy; 0x84uy; 0x3duy; 0x7euy; 0xe9uy; 0x3fuy; 0x34uy; 0x57uy; 0xa9uy; 0x70uy; 0x50uy; 0x82uy; 0x7euy; 0xecuy; 0x83uy; 0xacuy; 0xa6uy; 0x36uy; 0xaauy; 0xe1uy; 0xa7uy; 0x36uy; 0x01uy; 0xaeuy; 0x25uy; 0x75uy; 0x4auy; 0x95uy; 0xc9uy; 0x3cuy; 0x79uy; 0xc4uy; 0xc8uy; 0x6cuy; 0xb0uy; 0x93uy; 0xcbuy; 0x60uy; 0x73uy; 0xa7uy; 0x68uy; 0x98uy; 0x70uy; 0xb2uy; 0x0auy; 0xfbuy; 0x23uy; 0xb0uy; 0x69uy; 0x57uy; 0x6duy; 0xb6uy; 0x87uy; 0xb4uy; 0xaduy; 0x36uy; 0x01uy; 0x9duy; 0x39uy; 0x59uy; 0x11uy; 0xd6uy; 0x40uy; 0xa7uy; 0x83uy; 0x45uy; 0xf6uy; 0x77uy; 0x0buy; 0x16uy; 0x7buy; 0x08uy; 0xfcuy; 0xccuy; 0xa2uy; 0x94uy; 0xb6uy; 0x5cuy; 0x61uy; 0x5buy; 0xc7uy; 0xbfuy; 0xc2uy; 0xceuy; 0x56uy; 0x28uy; 0xa2uy; 0x3duy; 0x02uy; 0x62uy; 0xbeuy; 0x61uy; 0xb5uy; 0xb1uy; 0x9buy; 0x1auy; 0x94uy; 0xe2uy; 0x18uy; 0x69uy; 0xbbuy; 0x14uy; 0x6euy; 0x1buy; 0x0euy; 0x33uy; 0x00uy; 0xc8uy; 0xffuy; 0x81uy; 0xafuy; 0x9fuy; 0xc5uy; 0xb9uy; 0x67uy; 0x64uy; 0x95uy; 0xd1uy; 0x47uy; 0x84uy; 0xa6uy; 0xfcuy; 0x20uy; 0xf3uy; 0xe2uy; 0x66uy; 0x14uy; 0x6auy; 0x9auy; 0xffuy; 0x72uy; 0xc9uy; 0x27uy; 0x33uy; 0x75uy; 0xf2uy; 0xa3uy; 0x11uy; 0x99uy; 0xf1uy; 0xccuy; 0xd0uy; 0x92uy; 0x46uy; 0xcfuy; 0x86uy; 0xccuy; 0x7auy; 0x4buy; 0x37uy; 0x09uy; 0x2auy; 0x99uy; 0xbfuy; 0x89uy; 0x9buy; 0xb5uy; 0x52uy; 0x7buy; 0xd0uy; 0x36uy; 0x92uy; 0xbduy; 0xb5uy; 0x45uy; 0xbauy; 0x99uy; 0x9cuy; 0x4duy; 0x69uy; 0x2cuy; 0x7cuy; 0xabuy; 0x89uy; 0x74uy; 0x31uy; 0x25uy; 0x30uy; 0x76uy; 0x3cuy; 0x18uy; 0xe0uy; 0x53uy; 0x3fuy; 0xfcuy; 0xc4uy; 0xe0uy; 0xebuy; 0x21uy; 0xe0uy; 0xa4uy; 0xbbuy; 0x1auy; 0xc4uy; 0x9fuy; 0x9cuy; 0xd2uy; 0x07uy; 0xb7uy; 0x64uy; 0x66uy; 0x1buy; 0x9auy; 0x02uy; 0x07uy; 0xbcuy; 0x1euy; 0x87uy; 0x0cuy; 0x14uy; 0x77uy; 0xb3uy; 0x80uy; 0x52uy; 0xb3uy; 0x29uy; 0x50uy; 0x7auy; 0x8buy; 0xe9uy; 0x71uy; 0x84uy; 0x70uy; 0x65uy; 0xacuy; 0xaauy; 0x51uy; 0x23uy; 0x43uy; 0xb5uy; 0x73uy; 0x14uy; 0xbbuy; 0x4duy; 0xdcuy; 0xccuy; 0xb5uy; 0x1fuy; 0x17uy; 0x2euy; 0xf8uy; 0xc7uy; 0x7buy; 0xdauy; 0xb2uy; 0x62uy; 0x7duy; 0xb1uy; 0x9duy; 0x4buy; 0x20uy; 0x3buy; 0x79uy; 0xd0uy; 0x87uy; 0x6duy; 0x70uy; 0x57uy; 0x41uy; 0xb5uy; 0xc2uy; 0xdcuy; 0x42uy; 0x5buy; 0xd0uy; 0x5buy; 0x02uy; 0xf7uy; 0xe7uy; 0x46uy; 0x84uy; 0xd5uy; 0x52uy; 0xf9uy; 0x5cuy; 0x73uy; 0x48uy; 0xc5uy; 0x86uy; 0xaeuy; 0xe5uy; 0x00uy; 0x79uy; 0xe5uy; 0x8buy; 0xc7uy; 0x49uy; 0x8buy; 0x06uy; 0xf1uy; 0x1cuy; 0x91uy; 0xe3uy; 0x30uy; 0x08uy; 0x69uy; 0xcduy; 0x37uy; 0xdcuy; 0xafuy; 0xcfuy; 0xa6uy; 0x5auy; 0x93uy; 0xc0uy; 0xa4uy; 0x58uy; 0xd0uy; 0x43uy; 0x3cuy; 0x0cuy; 0x2euy; 0x6auy; 0x66uy; 0x48uy; 0x14uy; 0x77uy; 0x56uy; 0x07uy; 0x5cuy; 0x04uy; 0x0buy; 0x01uy; 0x49uy; 0x31uy; 0x85uy; 0x67uy; 0x35uy; 0x31uy; 0x46uy; 0xe4uy; 0x87uy; 0x8duy; 0x27uy; 0x72uy; 0xcbuy; 0x6fuy; 0x2auy; 0x00uy; 0xaauy; 0xdauy; 0x5euy; 0xbcuy; 0xecuy; 0x3cuy; 0x4buy; 0x63uy; 0x50uy; 0x79uy; 0x43uy; 0x6euy; 0xdbuy; 0xfbuy; 0x38uy; 0xa9uy; 0xb2uy; 0xc0uy; 0x06uy; 0xc3uy; 0x96uy; 0x09uy; 0xbcuy; 0x6fuy; 0xc6uy; 0xa1uy; 0xa5uy; 0xebuy; 0x05uy; 0x31uy; 0xd6uy; 0x36uy; 0x42uy; 0x91uy; 0x71uy; 0xa4uy; 0x25uy; 0x5auy; 0x6auy; 0x6auy; 0x4cuy; 0xccuy; 0xfduy; 0x47uy; 0x74uy; 0x68uy; 0x81uy; 0xc9uy; 0x63uy; 0x68uy; 0x21uy; 0xe6uy; 0x08uy; 0x60uy; 0xc1uy; 0x09uy; 0x80uy; 0x9cuy; 0x85uy; 0x80uy; 0xd2uy; 0x1buy; 0x59uy; 0x05uy; 0xf7uy; 0x88uy; 0xcbuy; 0x79uy; 0xcduy; 0x85uy; 0xd2uy; 0x37uy; 0xa8uy; 0x63uy; 0xb8uy; 0xaduy; 0xd2uy; 0x0fuy; 0x6auy; 0x18uy; 0xa0uy; 0x39uy; 0xa9uy; 0x6auy; 0xe6uy; 0xe5uy; 0x7fuy; 0xd9uy; 0x33uy; 0x4cuy; 0x5cuy; 0x11uy; 0xa3uy; 0xf8uy; 0x35uy; 0x69uy; 0xdeuy; 0xecuy; 0x26uy; 0x97uy; 0x97uy; 0x8buy; 0xa3uy; 0x0buy; 0x76uy; 0x71uy; 0xc6uy; 0x1euy; 0xcbuy; 0x49uy; 0x19uy; 0x82uy; 0x90uy; 0x4cuy; 0x53uy; 0x24uy; 0x78uy; 0x12uy; 0xa2uy; 0x14uy; 0x0euy; 0x07uy; 0x21uy; 0xdfuy; 0x40uy; 0x2euy; 0xe9uy; 0xaauy; 0x15uy; 0x07uy; 0x91uy; 0x20uy; 0x5auy; 0xe2uy; 0xc6uy; 0x07uy; 0x10uy; 0xa9uy; 0xe7uy; 0xe2uy; 0xa7uy; 0x5auy; 0xaauy; 0x4fuy; 0xabuy; 0xecuy; 0x26uy; 0x83uy; 0x30uy; 0xb0uy; 0x20uy; 0xa5uy; 0xa5uy; 0xb7uy; 0x2fuy; 0x9buy; 0xc8uy; 0x5cuy; 0x0auy; 0x13uy; 0xb9uy; 0xd0uy; 0x41uy; 0x58uy; 0x6fuy; 0xd5uy; 0x83uy; 0xfeuy; 0xb1uy; 0x2auy; 0xfduy; 0x5auy; 0x40uy; 0x2duy; 0xd3uy; 0x3buy; 0x43uy; 0x54uy; 0x3fuy; 0x5fuy; 0xa4uy; 0xebuy; 0x43uy; 0x6cuy; 0x8duy; 0x01uy; 0x6auy; 0x76uy; 0x53uy; 0x8fuy; 0xfduy; 0x5duy; 0x46uy; 0x61uy; 0x9euy; 0x1fuy; 0xfauy; 0xdfuy; 0x2buy; 0x8buy; 0x2auy; 0xf8uy; 0xd0uy; 0x19uy; 0x3euy; 0xd6uy; 0x73uy; 0xe4uy; 0x5euy; 0xb4uy; 0x79uy; 0xdeuy; 0x5fuy; 0x42uy; 0xcbuy; 0xc6uy; 0xd3uy; 0x3euy; 0x2auy; 0x2euy; 0xa6uy; 0xc9uy; 0xc4uy; 0x76uy; 0xfcuy; 0x49uy; 0x37uy; 0xb0uy; 0x13uy; 0xc9uy; 0x93uy; 0xa7uy; 0x93uy; 0xd6uy; 0xc0uy; 0xabuy; 0x99uy; 0x60uy; 0x69uy; 0x5buy; 0xa8uy; 0x38uy; 0xf6uy; 0x49uy; 0xdauy; 0x53uy; 0x9cuy; 0xa3uy; 0xd0uy
]

let test1_ct_expected  = List.Tot.map u8_from_UInt8
[
0x53uy; 0xa6uy; 0xc3uy; 0x49uy; 0xb0uy; 0xfcuy; 0x6buy; 0xf5uy; 0x98uy; 0xfauy; 0x0cuy; 0xd1uy; 0xb3uy; 0x9buy; 0xcbuy; 0x85uy; 0x2buy; 0xeeuy; 0x02uy; 0x4euy; 0x8buy; 0x62uy; 0x7cuy; 0x07uy; 0x3fuy; 0xe8uy; 0xf1uy; 0xbbuy; 0xa9uy; 0x60uy; 0xaeuy; 0x88uy; 0x1buy; 0xceuy; 0xb3uy; 0x8fuy; 0xb5uy; 0x0duy; 0xe3uy; 0xdcuy; 0x7auy; 0x29uy; 0x7buy; 0x36uy; 0xbbuy; 0x8cuy; 0xa3uy; 0xe4uy; 0xc3uy; 0x54uy; 0x0fuy; 0x77uy; 0xbbuy; 0x1duy; 0xa0uy; 0xc4uy; 0xa1uy; 0xaeuy; 0xc0uy; 0xd1uy; 0xeauy; 0x36uy; 0xdauy; 0x75uy; 0x4cuy; 0xf5uy; 0xf2uy; 0x00uy; 0x71uy; 0xeauy; 0xe7uy; 0x5fuy; 0x30uy; 0x9buy; 0x40uy; 0x53uy; 0x9euy; 0xf8uy; 0x4duy; 0xdauy; 0xaauy; 0x89uy; 0xf6uy; 0x37uy; 0xb3uy; 0x15uy; 0x95uy; 0x0buy; 0x54uy; 0x38uy; 0x97uy; 0xeeuy; 0x23uy; 0x45uy; 0x8auy; 0xf0uy; 0xb3uy; 0x9duy; 0x48uy; 0xe0uy; 0x60uy; 0xf0uy; 0xc9uy; 0x00uy; 0xceuy; 0x9duy; 0x70uy; 0xc6uy; 0x7buy; 0xe7uy; 0xe4uy; 0xceuy; 0x6buy; 0x67uy; 0xe1uy; 0xe7uy; 0xc3uy; 0xd8uy; 0xefuy; 0xc2uy; 0xa7uy; 0x07uy; 0xe4uy; 0x30uy; 0x73uy; 0x51uy; 0x27uy; 0xb1uy; 0x4fuy; 0x34uy; 0xc1uy; 0xf4uy; 0x80uy; 0x63uy; 0xa7uy; 0x1fuy; 0x4auy; 0xdbuy; 0x0cuy; 0x1auy; 0x90uy; 0x02uy; 0x6duy; 0xaeuy; 0x4auy; 0x1duy; 0xebuy; 0x0buy; 0x4buy; 0x42uy; 0x30uy; 0xd3uy; 0xf5uy; 0xb6uy; 0x52uy; 0x4cuy; 0x67uy; 0xd3uy; 0x2duy; 0x2duy; 0x85uy; 0xceuy; 0x2duy; 0x76uy; 0x68uy; 0x6cuy; 0x64uy; 0x55uy; 0xdcuy; 0xa3uy; 0x75uy; 0x41uy; 0x0auy; 0x9euy; 0xf4uy; 0xc9uy; 0xa5uy; 0x6auy; 0x87uy; 0xcfuy; 0x73uy; 0xfduy; 0x1euy; 0xecuy; 0xc7uy; 0x4cuy; 0xb4uy; 0x8buy; 0x1euy; 0x30uy; 0x49uy; 0x8duy; 0x2fuy; 0x94uy; 0xebuy; 0xa0uy; 0x53uy; 0xd6uy; 0x01uy; 0x68uy; 0x16uy; 0x98uy; 0x6buy; 0xd4uy; 0xdfuy; 0x6fuy; 0x3duy; 0x11uy; 0x8fuy; 0x4euy; 0x6fuy; 0xb3uy; 0xdfuy; 0x39uy; 0xcfuy; 0x48uy; 0x46uy; 0x97uy; 0xceuy; 0xb2uy; 0x2duy; 0xb5uy; 0x6fuy; 0xdbuy; 0xfauy; 0x38uy; 0x9auy; 0x4fuy; 0xe2uy; 0xaduy; 0x14uy; 0xfeuy; 0x50uy; 0x4buy; 0xd3uy; 0x6buy; 0x09uy; 0xaeuy; 0x2duy; 0xa2uy; 0xb9uy; 0x2fuy; 0x61uy; 0x71uy; 0xeeuy; 0xc0uy; 0xb0uy; 0xc8uy; 0x87uy; 0x75uy; 0x16uy; 0x44uy; 0x28uy; 0x67uy; 0xeeuy; 0xd8uy; 0xc4uy; 0x95uy; 0x17uy; 0xb7uy; 0x13uy; 0x87uy; 0x96uy; 0x8auy; 0x4fuy; 0xbeuy; 0xc6uy; 0x72uy; 0xa5uy; 0xd7uy; 0xfauy; 0xeeuy; 0xf5uy; 0xe9uy; 0xc1uy; 0xd7uy; 0x14uy; 0x5cuy; 0xcbuy; 0xe9uy; 0xcauy; 0x06uy; 0x77uy; 0xe7uy; 0xfeuy; 0xdfuy; 0xecuy; 0x84uy; 0x89uy; 0xd9uy; 0x9fuy; 0x37uy; 0x1duy; 0x63uy; 0x73uy; 0x1euy; 0x52uy; 0xe6uy; 0x40uy; 0x9auy; 0xb7uy; 0xabuy; 0xe0uy; 0x1auy; 0xa8uy; 0x87uy; 0x43uy; 0x13uy; 0x89uy; 0x76uy; 0x68uy; 0x19uy; 0x8duy; 0xb9uy; 0xcauy; 0xeauy; 0xdauy; 0x0cuy; 0xc6uy; 0x55uy; 0x89uy; 0x68uy; 0x2fuy; 0xbduy; 0xf9uy; 0x05uy; 0xb5uy; 0xaauy; 0x3duy; 0xb5uy; 0x76uy; 0x36uy; 0xf7uy; 0x4cuy; 0x3auy; 0xfbuy; 0xfcuy; 0xa2uy; 0x0duy; 0xfauy; 0x9auy; 0x4duy; 0x55uy; 0x21uy; 0x3euy; 0x4euy; 0x0buy; 0x3fuy; 0x72uy; 0x36uy; 0xe3uy; 0x13uy; 0x07uy; 0x35uy; 0xd3uy; 0xe8uy; 0xbeuy; 0xecuy; 0x0duy; 0x67uy; 0x6cuy; 0x91uy; 0x45uy; 0x99uy; 0x9euy; 0x91uy; 0xc7uy; 0xb3uy; 0x63uy; 0x87uy; 0xb8uy; 0x3duy; 0xaauy; 0x65uy; 0x2buy; 0x37uy; 0x0buy; 0x4auy; 0x9fuy; 0x3duy; 0xa3uy; 0xa3uy; 0x5euy; 0x04uy; 0x75uy; 0x11uy; 0xc3uy; 0xb9uy; 0xb8uy; 0x47uy; 0x0buy; 0x5duy; 0x98uy; 0xd0uy; 0xf5uy; 0x1auy; 0xb3uy; 0xd2uy; 0x60uy; 0xc8uy; 0xf4uy; 0xa8uy; 0x14uy; 0x5euy; 0x74uy; 0x87uy; 0xfcuy; 0x84uy; 0x9buy; 0xceuy; 0xd6uy; 0x9buy; 0xf2uy; 0x35uy; 0x95uy; 0xa9uy; 0x77uy; 0x3buy; 0x9duy; 0xa4uy; 0x05uy; 0x58uy; 0x4cuy; 0x86uy; 0xd1uy; 0x4euy; 0x56uy; 0x27uy; 0x3duy; 0xd9uy; 0xe1uy; 0x36uy; 0x13uy; 0x10uy; 0xdduy; 0xffuy; 0x7euy; 0x05uy; 0x33uy; 0x79uy; 0x61uy; 0xb2uy; 0x92uy; 0x5duy; 0x16uy; 0x00uy; 0x37uy; 0xc8uy; 0x80uy; 0x0buy; 0x25uy; 0x39uy; 0xa7uy; 0xabuy; 0x2auy; 0x1euy; 0x70uy; 0xd8uy; 0x41uy; 0x9fuy; 0xd1uy; 0x94uy; 0x95uy; 0x1cuy; 0xd3uy; 0xc5uy; 0xdbuy; 0xc7uy; 0xc8uy; 0xb2uy; 0x2auy; 0xecuy; 0x7euy; 0xe1uy; 0x83uy; 0xf5uy; 0x51uy; 0x51uy; 0x47uy; 0x2duy; 0xdfuy; 0x97uy; 0x4euy; 0x71uy; 0x76uy; 0x78uy; 0xdauy; 0xb5uy; 0x8duy; 0x56uy; 0xe6uy; 0x71uy; 0xaeuy; 0xc5uy; 0x33uy; 0xfcuy; 0x52uy; 0xd2uy; 0x83uy; 0xf5uy; 0x93uy; 0x6cuy; 0x93uy; 0x3auy; 0xa8uy; 0x29uy; 0x9cuy; 0xb5uy; 0x59uy; 0xd4uy; 0x19uy; 0xb3uy; 0xa4uy; 0x5fuy; 0xd3uy; 0xd8uy; 0x83uy; 0x06uy; 0xb9uy; 0x1duy; 0x6cuy; 0xbfuy; 0x3cuy; 0xd6uy; 0x25uy; 0x70uy; 0x5fuy; 0x46uy; 0x02uy; 0xb3uy; 0x41uy; 0xdcuy; 0xc2uy; 0xd0uy; 0x05uy; 0xd6uy; 0x2fuy; 0x32uy; 0x01uy; 0x3duy; 0xa7uy; 0x89uy; 0xdauy; 0xfauy; 0xe8uy; 0xcauy; 0x80uy; 0x05uy; 0x71uy; 0xcduy; 0x71uy; 0x05uy; 0xe2uy; 0x3euy; 0x30uy; 0xe1uy; 0xdduy; 0x95uy; 0x17uy; 0x3cuy; 0x81uy; 0xf2uy; 0xacuy; 0xfduy; 0x1duy; 0xd4uy; 0xc5uy; 0xf8uy; 0x4cuy; 0x03uy; 0x7auy; 0xafuy; 0x6fuy; 0x21uy; 0x90uy; 0x86uy; 0xcduy; 0xe9uy; 0xa1uy; 0xfduy; 0x0cuy; 0x18uy; 0x85uy; 0xeduy; 0xdeuy; 0x02uy; 0x2fuy; 0xa3uy; 0x5euy; 0x0duy; 0xdeuy; 0xf4uy; 0x81uy; 0x91uy; 0x05uy; 0xebuy; 0xe0uy; 0xb9uy; 0x77uy; 0x5auy; 0xa2uy; 0x10uy; 0x00uy; 0x6duy; 0x87uy; 0xe3uy; 0x2fuy; 0x40uy; 0x25uy; 0xe2uy; 0x38uy; 0xdduy; 0xeauy; 0x69uy; 0x25uy; 0x56uy; 0xb8uy; 0x0fuy; 0x37uy; 0x17uy; 0xfcuy; 0x7auy; 0x08uy; 0x6auy; 0x1duy; 0x3fuy; 0x85uy; 0x66uy; 0xcbuy; 0x61uy; 0xb7uy; 0x94uy; 0xe2uy; 0xd1uy; 0xb9uy; 0x32uy; 0x3auy; 0x13uy; 0x5auy; 0x58uy; 0xe7uy; 0x13uy; 0xd4uy; 0x08uy; 0xe2uy; 0x7euy; 0xd2uy; 0x72uy; 0x5euy; 0xd0uy; 0x19uy; 0xdauy; 0x4auy; 0x2buy; 0x95uy; 0x52uy; 0xd1uy; 0x83uy; 0x40uy; 0x0fuy; 0x0auy; 0xf0uy; 0xf2uy; 0xb0uy; 0x8fuy; 0x03uy; 0xd3uy; 0x2euy; 0x7fuy; 0xd5uy; 0x20uy; 0x03uy; 0x56uy; 0xa0uy; 0x63uy; 0x5cuy; 0xccuy; 0xc6uy; 0xa6uy; 0xd2uy; 0xa6uy; 0x30uy; 0x2cuy; 0x30uy; 0x72uy; 0xc6uy; 0x64uy; 0xa1uy; 0xbeuy; 0xd0uy; 0x39uy; 0xd5uy; 0xb3uy; 0xb9uy; 0x21uy; 0x13uy; 0x02uy; 0x22uy; 0x5duy; 0xa1uy; 0xc9uy; 0x3auy; 0xd0uy; 0x62uy; 0x61uy; 0xbduy; 0xe3uy; 0x39uy; 0x7auy; 0xe9uy; 0xe3uy; 0xb9uy; 0x96uy; 0xf2uy; 0x40uy; 0x0auy; 0x1auy; 0xc4uy; 0xe0uy; 0xd2uy; 0x80uy; 0x88uy; 0x38uy; 0x80uy; 0xf9uy; 0xd5uy; 0x5auy; 0x76uy; 0xf3uy; 0x7auy; 0xc0uy; 0x38uy; 0xcfuy; 0xd6uy; 0x34uy; 0x1cuy
]

let test1_ss_expected =
[
0x5euy; 0x6duy; 0x27uy; 0x23uy; 0xc3uy; 0x32uy; 0xb7uy; 0x12uy; 0xc1uy; 0x92uy; 0xaauy; 0x63uy; 0x29uy; 0xafuy; 0xe3uy; 0xa6uy; 0xe6uy; 0xa5uy; 0x60uy; 0xa9uy; 0x4duy; 0x1buy; 0xe2uy; 0x0duy; 0xcfuy; 0x7euy; 0xc9uy; 0xd3uy; 0x9duy; 0x92uy; 0x6cuy; 0x78uy
]

let test () : ML unit =
  assert_norm (List.Tot.length test1_coins == 32);
  assert_norm (List.Tot.length test1_indcpacoins == 32);
  assert_norm (List.Tot.length test1_msgcoins == 32);
  assert_norm (List.Tot.length test1_ss_expected == sharedkeylen);
  assert_norm (List.Tot.length test1_pk_expected == pklen);
  assert_norm (List.Tot.length test1_ct_expected == ciphertextlen);
  assert_norm (List.Tot.length test1_sk_expected == sklen);
  let result =
    test_kyber test1_coins
      test1_indcpacoins
      test1_msgcoins
      test1_ss_expected
      test1_pk_expected
      test1_ct_expected
      test1_sk_expected
  in
  if result
  then IO.print_string "\n\nKyberKEM Round 2: Success!\n"
else IO.print_string "\n\nKyberKEM Round 2: Failure :(\n"
