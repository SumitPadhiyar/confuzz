open Lwt.Infix

let () = 
  Crowbar.(add_test ~name:"test_input_plus_schedule" [Crowbar.int] (fun i -> 
      let open Lwt in
      let x = ref i in
      let p1 = pause () >>= fun () ->
        (* print_endline "p1"; *)
        x := !x - 2; Lwt.return_unit
      in
      let p2 = pause () >>= fun () -> 
        (* print_endline "p2"; *)
        x := !x * 4; Lwt.return_unit
      in
      let p3 = pause () >>= fun () -> 
        (* print_endline "p3"; *)
        x := !x + 70; Lwt.return_unit
      in

      Lwt_main.run (Lwt.join[p1;p2;p3]);
      Crowbar.check (!x != 0)
    ))
