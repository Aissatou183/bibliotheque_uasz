open Lwt.Infix
open Bibliotheque_uasz
open Types

let json_response ?(status=`OK) json =
  Dream.json ~status (Yojson.Safe.to_string json)

let bad_request msg =
  json_response ~status:`Bad_Request (`Assoc [("error", `String msg)])

let unauthorized msg =
  json_response ~status:`Unauthorized (`Assoc [("error", `String msg)])

let require_login handler req =
  match Dream.session_field req "user_email", Dream.session_field req "role" with
  | Some email, Some role -> handler req email role
  | _ -> unauthorized "Authentification requise"

let home _req =
  Dream.html "<h1>Bibliotheque en ligne UASZ</h1><p>API operationnelle</p>"

let register req =
  Dream.body req >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let open Yojson.Safe.Util in
    let nom = json |> member "nom" |> to_string in
    let email = json |> member "email" |> to_string in
    let password = json |> member "password" |> to_string in
    Db.create_user ~nom ~email ~password ~role:Utilisateur;
    json_response (`Assoc [("message", `String "Utilisateur créé avec succès")])
  with _ ->
    bad_request "JSON invalide ou utilisateur déjà existant"

let login req =
  Dream.body req >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let open Yojson.Safe.Util in
    let email = json |> member "email" |> to_string in
    let password = json |> member "password" |> to_string in
    match Db.find_user_by_email email with
    | None -> unauthorized "Email ou mot de passe incorrect"
    | Some user ->
        if Auth.verify_password password user.password_hash then
          Dream.set_session_field req "user_email" user.email >>= fun () ->
          Dream.set_session_field req "role" (Types.string_of_role user.role) >>= fun () ->
          Dream.set_session_field req "user_id" (string_of_int user.id) >>= fun () ->
          json_response (`Assoc [
            ("message", `String "Connexion réussie");
            ("utilisateur", Types.user_to_yojson user)
          ])
        else
          unauthorized "Email ou mot de passe incorrect"
  with _ ->
    bad_request "JSON invalide"

let logout req =
  Dream.invalidate_session req >>= fun () ->
  json_response (`Assoc [("message", `String "Déconnexion réussie")])

let profile _req email _role =
  match Db.find_user_by_email email with
  | None -> unauthorized "Utilisateur introuvable"
  | Some user -> json_response (Types.user_to_yojson user)

let list_documents _req _email _role =
  let docs = Db.list_documents () in
  json_response (Documents.documents_to_json docs)

let upload_document req _email _role =
  Dream.form ~csrf:false req >>= function
  | `Ok form
  | `Expired (form, _)
  | `Wrong_session form ->
      let find name = List.assoc_opt name form in
      begin match
        find "titre",
        find "description",
        find "auteur",
        find "categorie",
        find "nom_fichier",
        Dream.session_field req "user_id"
      with
      | Some titre, Some description, Some auteur, Some categorie, Some nom_fichier, Some user_id ->
          let safe_name = Filename.basename nom_fichier in
          let path = "storage/" ^ safe_name in
          Utils.write_file path "Fichier placeholder";
          Db.add_document
            ~titre
            ~description
            ~auteur
            ~categorie
            ~nom_fichier:safe_name
            ~chemin_fichier:path
            ~proprietaire_id:(int_of_string user_id)
            ~date_ajout:(Utils.now_string ());
          json_response (`Assoc [("message", `String "Document ajouté avec succès")])
      | _ ->
          bad_request "Champs manquants pour l'ajout du document"
      end
  | `Invalid_token _
  | `Missing_token _
  | `Many_tokens _
  | `Wrong_content_type ->
      bad_request "Formulaire invalide"

let download_document req =
  let id = int_of_string (Dream.param req "id") in
  let docs = Db.list_documents () in
  match List.find_opt (fun d -> d.id = id) docs with
  | None -> Dream.empty `Not_Found
  | Some d ->
      let ic = open_in_bin d.chemin_fichier in
      let len = in_channel_length ic in
      let content = really_input_string ic len in
      close_in ic;
      Dream.respond
        ~headers:[
          ("Content-Type", "application/octet-stream");
          ("Content-Disposition", "attachment; filename=\"" ^ d.nom_fichier ^ "\"")
        ]
        content

let () =
  Utils.ensure_dir "data";
  Utils.ensure_dir "storage";
  Db.init ();
  Db.create_default_admin ();

  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [
    Dream.get "/" home;
    Dream.post "/api/register" register;
    Dream.post "/api/login" login;
    Dream.post "/api/logout" logout;
    Dream.get "/api/profile" (require_login profile);
    Dream.get "/api/documents" (require_login list_documents);
    Dream.post "/api/documents/upload" (require_login upload_document);
    Dream.get "/api/documents/:id/download" download_document;
  ]
