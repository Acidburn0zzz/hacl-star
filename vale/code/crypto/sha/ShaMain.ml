let _ =
  CmdLineParser.parse_cmdline [
      ("sha256_update",  (fun win -> Vale_SHA_X64.va_code_sha_update_bytes_stdcall win, Vale_Def_PossiblyMonad.ttrue), 4, false);
    ]