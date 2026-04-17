type role = Admin | Utilisateur

type user = {
  id : int;
  nom : string;
  email : string;
  password_hash : string;
  role : role;
}

type document = {
  id : int;
  titre : string;
  description : string;
  auteur : string;
  categorie : string;
  nom_fichier : string;
  chemin_fichier : string;
  proprietaire_id : int;
  date_ajout : string;
}

let string_of_role = function
  | Admin -> "admin"
  | Utilisateur -> "utilisateur"

let role_of_string = function
  | "admin" -> Admin
  | _ -> Utilisateur

let user_to_yojson (u : user) =
  `Assoc [
    ("id", `Int u.id);
    ("nom", `String u.nom);
    ("email", `String u.email);
    ("role", `String (string_of_role u.role));
  ]

let document_to_yojson (d : document) =
  `Assoc [
    ("id", `Int d.id);
    ("titre", `String d.titre);
    ("description", `String d.description);
    ("auteur", `String d.auteur);
    ("categorie", `String d.categorie);
    ("nom_fichier", `String d.nom_fichier);
    ("chemin_fichier", `String d.chemin_fichier);
    ("proprietaire_id", `Int d.proprietaire_id);
    ("date_ajout", `String d.date_ajout);
  ]
