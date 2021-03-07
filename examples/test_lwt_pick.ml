let () =
  Crowbar.(add_test ~name:"test_lwt_pickup" [Crowbar.const 1] (fun _ -> 

      let p1 = Lwt.return 5 in
      let p3 = Lwt.return 541 in
      let p2 = Lwt.return 7 in

      let ret_val = Lwt_main.run (Lwt.pick [p1;p3;p2;]) in

      Crowbar.check  (ret_val != 541)
    ))

