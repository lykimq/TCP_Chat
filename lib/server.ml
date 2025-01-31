open Lwt.Infix

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable running : bool
  ; mutable current_client : Lwt_unix.file_descr option
  ; shutdown_complete : unit Lwt.u * unit Lwt.t }

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
  let thread, waiter = Lwt.wait () in
  Lwt.return
    { socket
    ; address
    ; running = true
    ; current_client = None
    ; shutdown_complete = (waiter, thread) }

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
    | Some client_socket ->
      let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_socket in
      let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_socket in
      Lwt.join [Lwt_io.close ic; Lwt_io.close oc; Lwt_unix.close client_socket]
    | None -> Lwt.return_unit
  in
  server.running <- false;
  cleanup

let start_server port =
  Logs.info (fun m -> m "Starting server on port %d" port);
  create_server port >>= fun server ->
  let rec accept_loop server =
    if server.running
    then (
      Logs.debug (fun m -> m "Waiting for client connection...");
      Lwt_unix.accept server.socket >>= fun (client_sock, client_addr) ->
      Logs.debug (fun m ->
          m "Accepted new connection from %s" (Common.format_addr client_addr) );
      server.current_client <- Some client_sock;
      let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_sock in
      let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_sock in
      handle_client ic oc client_addr >>= fun () ->
      Logs.debug (fun m ->
          m "Client handling completed, cleaning up connection" );
      server.current_client <- None;
      Lwt_unix.close client_sock >>= fun () ->
      Logs.debug (fun m -> m "Client socket closed, continuing accept loop");
      accept_loop server )
    else (
      Logs.debug (fun m -> m "Server stopped, exiting accept loop");
      Lwt.return_unit )
  in
  Logs.debug (fun m -> m "Starting accept loop");
  accept_loop server >>= fun () ->
  let _, shutdown_thread = server.shutdown_complete in
  shutdown_thread

let accept_connections server =
  server.running <- true;
  let rec accept_loop () =
    if not server.running
    then Lwt.return_unit
    else
      Lwt.catch
        (fun () ->
          Logs.debug (fun m -> m "Waiting for client connection...");
          Lwt_unix.accept server.socket >>= fun (client_sock, client_addr) ->
          let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_sock in
          let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_sock in
          handle_client ic oc client_addr >>= fun () -> accept_loop () )
        (function
          | Unix.Unix_error (Unix.EBADF, _, _) when not server.running ->
            (* Normal termination when server is stopping *)
            Lwt.return_unit
          | e -> Lwt.fail e )
  in
  accept_loop ()
