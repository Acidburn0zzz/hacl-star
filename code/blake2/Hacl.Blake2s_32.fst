module Hacl.Blake2s_32

module Spec = Spec.Blake2_Vec
module Impl = Hacl.Impl.Blake2.Generic
module Core = Hacl.Impl.Blake2.Core

let blake2s_update_block = Impl.blake2_update_block #Spec.Blake2S #Core.M32

let blake2s = Impl.blake2 #Spec.Blake2S #Core.M32 blake2s_update_block
