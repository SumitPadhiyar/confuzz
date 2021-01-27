let  get_fuzzed_calls l =
  if List.length l > 1 then 
    Crowbar.sample_from_generator (Crowbar.shuffle l)
  else l

let fuzz jobs =
  (* Printf.printf "fuzz jobs - %d\n%!" (List.length jobs); *)
  List.iter (fun f -> f()) (get_fuzzed_calls jobs)

