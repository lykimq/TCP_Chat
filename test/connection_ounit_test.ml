open OUnit2
open Lwt.Infix
open TCP_Chat

let wait_for thread = Lwt_main.run thread

let setup_test_environment port =
  Logs.set_reporter (Logs.format_reporter ());
  Logs.set_level (Some Logs.Debug);
  (* Create and start server *)
  let server_thread =
    Server.create_server port >>= fun server ->
    let accept_thread = Server.accept_connections server in
    Lwt.return (server, accept_thread)
  in
  let server, accept_thread = wait_for server_thread in
  Unix.sleep 1;  (* Give server time to start *)
  (server, accept_thread)

let cleanup_server (server : Server.t) accept_thread =
  server.running <- false;
  Lwt.cancel accept_thread;  (* Cancel the accept thread first *)
  Lwt.catch
    (fun () ->
      Server.stop_server server >>= fun () ->
      (* Wait a bit to ensure all resources are cleaned up *)
      Lwt_unix.sleep 0.5)
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit
      | e -> Lwt.fail e)
let test_server_client_connection _ =
  let port = 8080 in
  let server, accept_thread = setup_test_environment port in

  let client_test =
    Client.connect_to_server Config.default_host port >>= fun client ->
    (* Wait for client to be registered *)
    Lwt_unix.sleep 0.5 >>= fun () ->

    let test_message = "Hello, Server!" in
    Client.send_message client (Bytes.of_string test_message) >>= fun () ->
    Lwt_unix.sleep 0.5 >>= fun () ->

    (* Debug print to check client state *)
    Logs.debug (fun m -> m "Current client status: %s"
      (match server.current_client with
       | Some _ -> "Connected"
       | None -> "Not connected"));

    (match server.current_client with
    | Some client_conn ->
        Logs.debug (fun m -> m "Sending message to client");
        Server.send_message client_conn (Bytes.of_string "Hello back!")
    | None ->
        Logs.err (fun m -> m "No client registered in server state");
        Lwt.fail_with "No client connected") >>= fun () ->
    Lwt_unix.sleep 0.5 >>= fun () ->


    Client.stop_client client >>= fun () ->
    (* Wait for cleanup *)
    Lwt_unix.sleep 0.5
  in

  (* Run client test and cleanup *)
  wait_for client_test;
  wait_for (cleanup_server server accept_thread);
  assert_bool "Test completed" true

let suite =
  "server_client_test"
  >::: [ "test_server_client_connection" >:: test_server_client_connection ]

let () =
  run_test_tt_main suite
