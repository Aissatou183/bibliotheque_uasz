open Alcotest
open Bibliotheque_uasz

let test_hash_password () =
  let p = "secret123" in
  let h = Auth.hash_password p in
  check bool "verify password" true (Auth.verify_password p h)

let test_role_conversion () =
  check string "admin" "admin" (Types.string_of_role Types.Admin);
  check string "utilisateur" "utilisateur" (Types.string_of_role Types.Utilisateur)

let () =
  run "Bibliotheque UASZ" [
    ("auth", [
      test_case "hash password" `Quick test_hash_password;
    ]);
    ("types", [
      test_case "role conversion" `Quick test_role_conversion;
    ]);
  ]
