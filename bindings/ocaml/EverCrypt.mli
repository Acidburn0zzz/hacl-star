open SharedDefs

module AutoConfig2 : sig
  val init : unit -> unit
  val has_shaext : unit -> bool
  val has_aesni : unit -> bool
  val has_pclmulqdq : unit -> bool
  val has_avx2 : unit -> bool
  val has_avx : unit -> bool
  val has_bmi2 : unit -> bool
  val has_adx : unit -> bool
  val has_sse : unit -> bool
  val has_movbe : unit -> bool
  val has_rdrand : unit -> bool
end

module Error : sig
  type error_code =
    | UnsupportedAlgorithm
    | InvalidKey
    | AuthenticationFailure
    | InvalidIVLength
    | DecodeError
  type 'a result =
    | Success of 'a
    | Error of error_code
end

module AEAD : sig
  type t
  type alg =
    | AES128_GCM
    | AES256_GCM
    | CHACHA20_POLY1305
  val init : alg -> Bigstring.t -> t Error.result
  val encrypt : t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> unit Error.result
  val decrypt : t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> Bigstring.t -> unit Error.result
end

module Chacha20_Poly1305 : Chacha20_Poly1305

module Curve25519 : Curve25519

module Ed25519 : EdDSA

module Hash : sig
  type t
  val init : HashDefs.alg -> t
  val update : t -> Bigstring.t -> unit
  val finish : t -> Bigstring.t -> unit
  val free : t -> unit
  val hash : HashDefs.alg -> Bigstring.t -> Bigstring.t -> unit
end

module SHA2_224 : HashFunction

module SHA2_256 : HashFunction

module HMAC : sig
  val is_supported_alg : HashDefs.alg -> bool
  val mac : HashDefs.alg -> Bigstring.t -> Bigstring.t -> Bigstring.t -> unit
end

module HMAC_SHA2_256 : MAC

module HMAC_SHA2_384 : MAC

module HMAC_SHA2_512 : MAC

module Poly1305 : MAC

module HKDF : sig
  val expand : HashDefs.alg -> Bigstring.t -> Bigstring.t -> Bigstring.t -> unit
  val extract : HashDefs.alg -> Bigstring.t -> Bigstring.t -> Bigstring.t -> unit
end

module HKDF_SHA2_256 : HKDF

module HKDF_SHA2_384 : HKDF

module HKDF_SHA2_512 : HKDF

module DRBG : sig
  type t
  val instantiate : ?personalization_string: Bigstring.t -> HashDefs.alg -> t option
  val reseed : ?additional_input: Bigstring.t -> t -> bool
  val generate : ?additional_input: Bigstring.t -> t -> Bigstring.t -> bool
  val uninstantiate : t -> unit
end
