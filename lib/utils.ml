let ensure_dir path =
  if not (Sys.file_exists path) then Unix.mkdir path 0o755

let now_string () =
  let open Unix in
  let tm = localtime (time ()) in
  Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d"
    (tm.tm_year + 1900)
    (tm.tm_mon + 1)
    tm.tm_mday
    tm.tm_hour
    tm.tm_min
    tm.tm_sec

let write_file filename content =
  let oc = open_out_bin filename in
  output_string oc content;
  close_out oc
