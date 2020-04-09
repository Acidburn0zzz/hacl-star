module Hacl.PKCS11.Lemmas.ObjectTree

open FStar.Seq
open Hacl.PKCS11.Types
open Hacl.PKCS11.Attributes.API


assume val lemmaSecretKeyIsObject: attrs: seq _CK_ATTRIBUTE -> Lemma 
  (requires 
    (
      let requiredAttributes = getAttributesForType CKO_SECRET_KEY in 
      _attributesAllPresent attrs requiredAttributes))
  (ensures 
    (
      let requiredAttributesObject = getAttributesForTypeExtended CKO_OBJECT in 
      _attributesAllPresent attrs requiredAttributesObject
    )
  )


