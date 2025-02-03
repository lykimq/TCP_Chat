open Lwt.Infix

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable current_client : (Lwt_io.output_channel * Unix.sockaddr) option }

let create_server port =
  let open Lwt_unix in
  Logs.debug (fun m -> m "Creating server on port %d" port);
  let socket = socket PF_INET SOCK_STREAM 0 in
  setsockopt socket SO_REUSEADDR true;
  let address = Unix.ADDR_INET (Unix.inet_addr_any, port) in
  Logs.debug (fun m -> m "Binding socket to address");
  bind socket address >>= fun () ->
  listen socket Config.max_connections;
  Logs.debug (fun m -> m "Server created and listening");
  Lwt.return {socket; address; current_client = None}

let handle_client ic oc client_addr =
  Logs.debug (fun m ->
      m "Handling new client connection from %s"
        (Common.format_addr client_addr) );
  Common.handle_connection ic oc (Common.format_addr client_addr)
  >>= fun result ->
  Logs.debug (fun m ->
      m "Finished handling client connection from %s"
        (Common.format_addr client_addr) );
  Lwt.return result

let stop_server server =
  Logs.debug (fun m -> m "Stopping server...");
  let cleanup =
    Lwt_unix.close server.socket >>= fun () ->
    (* If there's an active client connection, close it *)
    match server.current_client with
    | Some (oc, _) -> Lwt_io.close oc
    | None -> Lwt.return_unit
  in
  cleanup

let cleanup_client_connection ic oc client_sock =
  Lwt.catch
    (fun () ->
      Lwt_io.close ic >>= fun () ->
      Lwt_io.close oc >>= fun () -> Lwt_unix.close client_sock )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit
      | e ->
        Logs.err (fun m -> m "Error during cleanup: %s" (Printexc.to_string e));
        Lwt.return_unit )

let handle_client_error = function
  | End_of_file ->
    Logs.debug (fun m -> m "Client disconnected normally");
    Lwt.return_unit
  | e ->
    Logs.err (fun m -> m "Error handling client: %s" (Printexc.to_string e));
    Lwt.return_unit

let update_client_state server client_addr =
  match server.current_client with
  | Some (_, addr) when addr = client_addr ->
    server.current_client <- None;
    Logs.debug (fun m -> m "Cleared client from server state")
  | _ -> ()

let handle_single_client server client_sock client_addr =
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_sock in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_sock in
  server.current_client <- Some (oc, client_addr);
  Logs.debug (fun m -> m "Client registered in server state");

  Lwt.finalize
    (fun () ->
      Lwt.catch
        (fun () ->
          handle_client ic oc client_addr >>= fun () ->
          Logs.debug (fun m -> m "Client handling completed normally");
          Lwt.return_unit )
        handle_client_error )
    (fun () ->
      update_client_state server client_addr;
      cleanup_client_connection ic oc client_sock )

let accept_connections server =
  let rec accept_loop () =
    Lwt.catch
      (fun () ->
        Logs.debug (fun m -> m "Waiting for client connection...");
        Lwt_unix.accept server.socket >>= fun (client_sock, client_addr) ->
        handle_single_client server client_sock client_addr >>= fun () ->
        accept_loop () )
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) ->
          Logs.info (fun m -> m "Server stopped, closing accept loop");
          Lwt.return_unit
        | e ->
          Logs.err (fun m -> m "Accept loop error: %s" (Printexc.to_string e));
          accept_loop () )
  in
  accept_loop ()

let send_message server content =
  match server.current_client with
  | Some (oc, addr) ->
    let message = Message.create (Message.Chat content) in
    Logs.debug (fun m ->
        m "Sending message to client at %s" (Common.format_addr addr) );
    Common.write_message oc message >>= fun () -> Lwt.return_unit
  | None ->
    Logs.warn (fun m -> m "No client registered in server state");
    Lwt.return_unit
