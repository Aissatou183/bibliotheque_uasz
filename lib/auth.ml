open Digestif

let hash_password password =
  BLAKE2B.(to_hex (digest_string password))

let verify_password password hash =
  String.equal (hash_password password) hash
