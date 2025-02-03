open Alcotest
open Lwt.Infix
open TCP_Chat

(* Test helpers *)
let with_server f =
  let port = 12345 in
  Server.create_server port >>= fun server ->
  Lwt.finalize (fun () -> f server) (fun () -> Server.stop_server server)

let connect_client port =
  let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
  let addr = Unix.ADDR_INET (Unix.inet_addr_loopback, port) in
  Lwt_unix.connect sock addr >>= fun () ->
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input sock in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output sock in
  Lwt.return (sock, ic, oc)

(* Test cases *)
let test_server_creation () =
  Lwt_main.run
    (let port = 12345 in
     Server.create_server port >>= fun server ->
     let fd = Lwt_unix.unix_file_descr server.socket in
     let is_valid_fd =
       try
         ignore (Unix.fstat fd);
         true
       with _ -> false
     in
     check bool "server is created" true is_valid_fd;
     Server.stop_server server )

let test_client_connection () =
  Lwt_main.run
    ( with_server @@ fun server ->
      let port = 12345 in

      (* Start accepting connections in background *)
      let server_thread = Server.accept_connections server in

      (* Connect a client *)
      connect_client port >>= fun (sock, _ic, _oc) ->
      (* Verify client is registered *)
      check bool "client is registered" true (server.current_client <> None);

      (* Cleanup *)
      Lwt_unix.close sock >>= fun () ->
      Lwt.cancel server_thread;
      Lwt.return_unit )

let test_client_disconnect () =
  Lwt_main.run
    ( with_server @@ fun server ->
      let port = 12345 in

      (* Start accepting connections *)
      let server_thread = Server.accept_connections server in

      (* Connect and immediately disconnect a client *)
      connect_client port >>= fun (sock, _ic, _oc) ->
      Lwt_unix.close sock >>= fun () ->
      (* Give some time for the server to process the disconnection *)
      Lwt_unix.sleep 0.1 >>= fun () ->
      (* Verify client is unregistered *)
      check bool "client is unregistered" true (server.current_client = None);

      Lwt.cancel server_thread;
      Lwt.return_unit )

let test_send_message () =
  Lwt_main.run
    ( with_server @@ fun server ->
      let port = 12345 in
      (* Start accepting connections *)
      let _server_thread = Server.accept_connections server in

      (* Connect a client *)
      connect_client port >>= fun (sock, ic, _oc) ->
      (* Send a message *)
      let test_message = "Hello, client!" in
      Server.send_message server (Bytes.of_string test_message) >>= fun () ->
      (* Read the message from client side *)
      Common.read_message ic >>= fun received_msg ->
      match received_msg with
      | Some msg ->
        check string "message content matches" test_message
          (Message.message_get_content msg);
        Lwt_unix.close sock
      | None ->
        Alcotest.fail "No message received" >>= fun () ->
        Lwt_unix.close sock >>= fun () -> Lwt.return_unit )

(* Test suite definition *)
let suite =
  [ ( "server"
    , [ test_case "server creation" `Quick test_server_creation
      ; test_case "client connection" `Quick test_client_connection
      ; test_case "client disconnect" `Quick test_client_disconnect
      ; test_case "send message" `Quick test_send_message ] ) ]

let () = run "Server Tests" suite
