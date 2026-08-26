#load "unix.cma";;

(* Prefer explicit locations, but keep the common case of launching this file
   from the Flyspeck or HOL Light checkout convenient. *)
let directory_containing env candidates marker =
  let configured =
    try [Sys.getenv env]
    with Not_found -> candidates in
  try
    List.find
      (fun directory -> Sys.file_exists (Filename.concat directory marker))
      configured
  with Not_found ->
    failwith
      ("Set " ^ env ^ " to a directory containing " ^ marker);;

let launch_dir = Sys.getcwd();;

let flyspeck_dir =
  directory_containing "FLYSPECK_DIR"
    [Filename.concat launch_dir "text_formalization"; launch_dir]
    "build/strictbuild.hl";;

let hollight_dir =
  directory_containing "HOLLIGHT_DIR" [launch_dir]
    "Multivariate/flyspeck.ml";;

let () = Unix.putenv "FLYSPECK_DIR" flyspeck_dir;;
let () = Unix.putenv "HOLLIGHT_DIR" hollight_dir;;

needs "Multivariate/flyspeck.ml";;

needs (Filename.concat flyspeck_dir "build/strictbuild.hl");;
needs "build/build.hl";;

let build_to_seq seq name =
  let i = index name seq in
  let seq0, _ = chop_list (i + 1) seq in
  let _ = map flyspeck_needs seq0 in
  ();;

(* Loads the given Flyspeck file and all its dependencies.
   The file path should be relative to flyspeck/text_formalization.
   The linear program bounds are not loaded and verified when this function is used.
   Examples:
   build_to "hypermap/hypermap.hl";  
   build_to "local/LFJCIXP.hl"; *)
let build_to name =
  build_to_seq Build.build_sequence_main_statement name;;

(* This function can be used to load and verify Flyspeck files including
   bounds of linear programs *)
let build_to_full name =
  build_to_seq Build.build_sequence_full name;;

(* Loading the main statement without linear program bounds *)
(*
build_to "general/the_main_statement.hl";;
*)

(* Loading the main statement with linear program bounds *)
(*
build_to_full "general/the_kepler_conjecture.hl";;
*)
