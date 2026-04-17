Bibliotheque en ligne UASZ

Ce projet consiste a developper une application backend en OCaml permettant la gestion et le partage de documents administratifs au sein de l'Universite Assane Seck de Ziguinchor.

L'objectif est de proposer un systeme simple, centralise et securise pour stocker et consulter des documents.

Le projet a ete realise en utilisant le langage OCaml et le framework web Dream pour la gestion des requetes HTTP. Les donnees sont stockees dans une base SQLite, ce qui permet une gestion legere et efficace des informations. Le format JSON est utilise pour les echanges de donnees grace a la bibliotheque Yojson.

Le projet est structure en plusieurs modules :
- types.ml : definition des structures de donnees (utilisateur, document)
- db.ml : gestion de la base de donnees
- auth.ml : gestion de la securite et du hachage des mots de passe
- documents.ml : gestion des documents
- main.ml : serveur web et definition des routes API

L'application propose plusieurs fonctionnalites :
- inscription et connexion des utilisateurs
- gestion des sessions pour securiser l'acces
- consultation des documents
- ajout et telechargement de documents

Les documents sont stockes dans le systeme de fichiers (dossier storage) tandis que leurs metadonnees sont enregistrees dans la base de donnees SQLite.

La securite est assuree par le hachage des mots de passe avec la bibliotheque Digestif ainsi que par la gestion des sessions avec Dream. Les routes sensibles sont protegrees afin de garantir que seuls les utilisateurs authentifies peuvent y acceder.

Des tests ont ete realises avec Alcotest afin de verifier certaines fonctionnalites, notamment le hachage des mots de passe et la manipulation des types.

Ce projet repond aux exigences demandees en proposant une architecture backend fonctionnelle, une gestion des donnees structuree et une API REST securisee.