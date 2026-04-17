open Types

let documents_to_json docs =
  `List (List.map document_to_yojson docs)
