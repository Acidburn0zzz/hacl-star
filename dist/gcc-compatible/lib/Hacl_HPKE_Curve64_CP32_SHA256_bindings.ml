open Ctypes
module Bindings(F:Cstubs.FOREIGN) =
  struct
    open F
    let hacl_HPKE_Curve64_CP32_SHA256_setupBaseI =
      foreign "Hacl_HPKE_Curve64_CP32_SHA256_setupBaseI"
        ((ptr uint8_t) @->
           ((ptr uint8_t) @->
              ((ptr uint8_t) @->
                 ((ptr uint8_t) @->
                    ((ptr uint8_t) @->
                       (uint32_t @-> ((ptr uint8_t) @-> (returning uint32_t))))))))
      
    let hacl_HPKE_Curve64_CP32_SHA256_setupBaseR =
      foreign "Hacl_HPKE_Curve64_CP32_SHA256_setupBaseR"
        ((ptr uint8_t) @->
           ((ptr uint8_t) @->
              ((ptr uint8_t) @->
                 ((ptr uint8_t) @->
                    (uint32_t @-> ((ptr uint8_t) @-> (returning uint32_t)))))))
      
    let hacl_HPKE_Curve64_CP32_SHA256_sealBase =
      foreign "Hacl_HPKE_Curve64_CP32_SHA256_sealBase"
        ((ptr uint8_t) @->
           ((ptr uint8_t) @->
              (uint32_t @->
                 ((ptr uint8_t) @->
                    (uint32_t @->
                       ((ptr uint8_t) @->
                          ((ptr uint8_t) @-> (returning uint32_t))))))))
      
    let hacl_HPKE_Curve64_CP32_SHA256_openBase =
      foreign "Hacl_HPKE_Curve64_CP32_SHA256_openBase"
        ((ptr uint8_t) @->
           ((ptr uint8_t) @->
              (uint32_t @->
                 ((ptr uint8_t) @->
                    (uint32_t @->
                       ((ptr uint8_t) @->
                          ((ptr uint8_t) @-> (returning uint32_t))))))))
      
  end