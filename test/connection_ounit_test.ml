open OUnit2
open Lwt.Infix
open TCP_Chat

let wait_for thread = Lwt_main.run thread

let test_server_client_connection _ =
  let port = 8080 in
  (* Initialize logging *)
  Logs.set_reporter (Logs.format_reporter ());
  Logs.set_level (Some Logs.Debug);

  (* Create and start server *)
  let server_thread =
    Server.create_server port >>= fun server ->
    let accept_thread = Server.accept_connections server in
    Lwt.return (server, accept_thread)
  in
  let server, _ = wait_for server_thread in

  (* Give server time to start *)
  Unix.sleep 1;

  (* Test client connection *)
  let client_test =
    Client.connect_to_server Config.default_host port >>= fun client ->
    (* Send a test message *)
    let test_message = "Hello, Server!" in
    Client.send_message client (Bytes.of_string test_message) >>= fun () ->
    (* Wait a bit for message processing *)
    Lwt_unix.sleep 0.5 >>= fun () ->
    (* Cleanup client *)
    Lwt.catch
      (fun () ->
        Lwt.join
          [ Lwt_io.close client.ic
          ; Lwt_io.close client.oc
          ; Lwt_unix.close client.socket ] )
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit
        | e -> Lwt.fail e )
    >>= fun () -> Lwt_unix.sleep 0.1
  in

  (* Run the client test *)
  wait_for client_test;

  (* Stop and cleanup server *)
  server.running <- false;
  Lwt.catch
    (fun () -> Server.stop_server server)
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit | e -> Lwt.fail e
      )
  |> wait_for;

  assert_bool "Test completed" true

let suite =
  "server_client_test"
  >::: ["test_server_client_connection" >:: test_server_client_connection]

let () = run_test_tt_main suite
