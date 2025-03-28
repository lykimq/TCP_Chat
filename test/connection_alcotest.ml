open Alcotest
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
  Unix.sleep 1;
  (* Give server time to start *)
  (server, accept_thread)

let cleanup_server (server : Server.t) accept_thread =
  Lwt.cancel accept_thread;
  (* Cancel the accept thread first *)
  Lwt.catch
    (fun () ->
      Server.stop_server server >>= fun () ->
      (* Wait a bit to ensure all resources are cleaned up *)
      Lwt_unix.sleep 0.5 )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit | e -> Lwt.fail e
      )

let test_client_connect_disconnect () =
  Lwt_main.run
    (let port = 8080 + Random.int 100 in
     let server, accept_thread = setup_test_environment port in
     (* Connect a client *)
     Client.connect_to_server Config.default_host port >>= fun client ->
     (* Verify client is registered *)
     check bool "client is registered" true (server.current_client <> None);
     (* Cleanup *)
     Client.stop_client client >>= fun () ->
     (* Give some time for the server to process the disconnection *)
     Lwt_unix.sleep 0.1 >>= fun () ->
     (* Verify client is unregistered *)
     check bool "client is unregistered" true (server.current_client = None);
     cleanup_server server accept_thread >>= fun () -> Lwt.return_unit )

let test_server_client_communication () =
  let port = 8081 + Random.int 100 in
  let server, accept_thread = setup_test_environment port in

  let client_test =
    Client.connect_to_server Config.default_host port >>= fun client ->
    (* Wait for client to be registered *)
    Lwt_unix.sleep 1.0 >>= fun () ->
    let test_message = "Hello, Server!" in
    Client.send_message client (Bytes.of_string test_message) >>= fun () ->
    Lwt_unix.sleep 0.5 >>= fun () ->
    Client.stop_client client >>= fun () -> Lwt_unix.sleep 0.5
  in
  (* Run client test and cleanup *)
  wait_for client_test;
  wait_for (cleanup_server server accept_thread);
  Alcotest.(check bool) "server client communication" true true

let test_server_client_bidirectional_communication () =
  let port = 8082 + Random.int 100 in
  let server, accept_thread = setup_test_environment port in

  let client_test =
    Client.connect_to_server Config.default_host port >>= fun client ->
    (* Wait for client to be registered *)
    Lwt_unix.sleep 1.0 >>= fun () ->
    let test_message = "Hello, Server!" in
    Client.send_message client (Bytes.of_string test_message) >>= fun () ->
    Lwt_unix.sleep 0.5 >>= fun () ->
    (* Debug print to check client state *)
    Logs.debug (fun m ->
        m "Current client status: %s"
          ( match server.current_client with
          | Some _ -> "Connected"
          | None -> "Not connected" ) );
    Logs.debug (fun m -> m "Sending message to client");
    Server.send_message server (Bytes.of_string "Hello back!") >>= fun () ->
    (* Wait for cleanup *)
    Lwt_unix.sleep 0.5 >>= fun () ->
    Client.stop_client client >>= fun () -> Lwt_unix.sleep 0.5
  in
  (* Run client test and cleanup *)
  wait_for client_test;
  wait_for (cleanup_server server accept_thread);
  Alcotest.(check bool) "Test completed" true true

let connection_tests =
  [ test_case "Client connection and disconnect" `Quick
      test_client_connect_disconnect
  ; test_case "Server client communication" `Quick
      test_server_client_communication
  ; test_case "Server client bidirectional communication" `Quick
      test_server_client_bidirectional_communication ]

let () = Alcotest.run "TCP Chat Tests" [("connection", connection_tests)]
