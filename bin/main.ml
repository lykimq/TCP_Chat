let () =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in

  (* Start the server thread *)
  let server_thread =
    Lwt.async (fun () ->
        let sock = Server.create_socket () in
        let serve = Server.create_server sock in
        Lwt_main.run @@ serve ())
  in
  let server = Lwt.return server_thread in

  (* Start the client thread *)
  let client_thread =
    Lwt.async (fun () ->
        let server_addr = "localhost" in
        (* Change to your server address *)
        let port = 9000 in
        (* Change to your server port *)
        Client.run_client server_addr port)
  in
  let client = Lwt.return client_thread in

  (* Wait for both threads to finish *)
  Lwt_main.run @@ Lwt.join [ server; client ]
