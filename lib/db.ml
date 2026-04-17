open Types

let db_path = "data/bibliotheque.db"

let connect () =
  Sqlite3.db_open db_path

let exec db sql =
  match Sqlite3.exec db sql with
  | Sqlite3.Rc.OK -> ()
  | rc -> failwith (Printf.sprintf "Erreur SQL: %s" (Sqlite3.Rc.to_string rc))

let init () =
  let db = connect () in
  exec db
    "CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL
    );";
  exec db
    "CREATE TABLE IF NOT EXISTS documents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titre TEXT NOT NULL,
      description TEXT NOT NULL,
      auteur TEXT NOT NULL,
      categorie TEXT NOT NULL,
      nom_fichier TEXT NOT NULL,
      chemin_fichier TEXT NOT NULL,
      proprietaire_id INTEGER NOT NULL,
      date_ajout TEXT NOT NULL,
      FOREIGN KEY(proprietaire_id) REFERENCES users(id)
    );";
  ignore (Sqlite3.db_close db)

let create_default_admin () =
  let db = connect () in
  let sql_check = "SELECT COUNT(*) FROM users WHERE email='admin@uasz.sn';" in
  let count = ref 0 in
  ignore (
    Sqlite3.exec_not_null_no_headers
      ~cb:(fun row ->
        count := int_of_string row.(0))
      db
      sql_check
  );
  if !count = 0 then begin
    let password_hash = Auth.hash_password "admin123" in
    let sql =
      Printf.sprintf
        "INSERT INTO users(nom,email,password_hash,role) VALUES('Administrateur','admin@uasz.sn','%s','admin');"
        password_hash
    in
    exec db sql
  end;
  ignore (Sqlite3.db_close db)

let create_user ~nom ~email ~password ~role =
  let db = connect () in
  let hash = Auth.hash_password password in
  let sql = "INSERT INTO users(nom,email,password_hash,role) VALUES(?,?,?,?);" in
  let stmt = Sqlite3.prepare db sql in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT nom));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT email));
  ignore (Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT hash));
  ignore (Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT (string_of_role role)));
  begin
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | rc -> failwith (Sqlite3.Rc.to_string rc)
  end;
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db)

let find_user_by_email email =
  let db = connect () in
  let stmt =
    Sqlite3.prepare db
      "SELECT id, nom, email, password_hash, role FROM users WHERE email = ?;"
  in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT email));
  let result =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
        let u = {
          id =
            (match Sqlite3.column stmt 0 with
             | Sqlite3.Data.INT x -> Int64.to_int x
             | _ -> 0);
          nom =
            (match Sqlite3.column stmt 1 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          email =
            (match Sqlite3.column stmt 2 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          password_hash =
            (match Sqlite3.column stmt 3 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          role =
            role_of_string
              (match Sqlite3.column stmt 4 with
               | Sqlite3.Data.TEXT s -> s
               | _ -> "utilisateur");
        } in
        Some u
    | _ -> None
  in
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db);
  result

let list_documents () =
  let db = connect () in
  let stmt =
    Sqlite3.prepare db
      "SELECT id, titre, description, auteur, categorie, nom_fichier, chemin_fichier, proprietaire_id, date_ajout
       FROM documents
       ORDER BY id DESC;"
  in
  let rec loop acc =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
        let d = {
          id =
            (match Sqlite3.column stmt 0 with
             | Sqlite3.Data.INT x -> Int64.to_int x
             | _ -> 0);
          titre =
            (match Sqlite3.column stmt 1 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          description =
            (match Sqlite3.column stmt 2 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          auteur =
            (match Sqlite3.column stmt 3 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          categorie =
            (match Sqlite3.column stmt 4 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          nom_fichier =
            (match Sqlite3.column stmt 5 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          chemin_fichier =
            (match Sqlite3.column stmt 6 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
          proprietaire_id =
            (match Sqlite3.column stmt 7 with
             | Sqlite3.Data.INT x -> Int64.to_int x
             | _ -> 0);
          date_ajout =
            (match Sqlite3.column stmt 8 with
             | Sqlite3.Data.TEXT s -> s
             | _ -> "");
        } in
        loop (d :: acc)
    | Sqlite3.Rc.DONE -> List.rev acc
    | rc -> failwith (Sqlite3.Rc.to_string rc)
  in
  let docs = loop [] in
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db);
  docs

let add_document ~titre ~description ~auteur ~categorie
    ~nom_fichier ~chemin_fichier ~proprietaire_id ~date_ajout =
  let db = connect () in
  let stmt =
    Sqlite3.prepare db
      "INSERT INTO documents(titre,description,auteur,categorie,nom_fichier,chemin_fichier,proprietaire_id,date_ajout)
       VALUES(?,?,?,?,?,?,?,?);"
  in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT titre));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT description));
  ignore (Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT auteur));
  ignore (Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT categorie));
  ignore (Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT nom_fichier));
  ignore (Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT chemin_fichier));
  ignore (Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Int64.of_int proprietaire_id)));
  ignore (Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT date_ajout));
  begin
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | rc -> failwith (Sqlite3.Rc.to_string rc)
  end;
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db)
