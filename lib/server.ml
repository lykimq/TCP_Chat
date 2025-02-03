open Lwt.Infix

type client_connection = {
  socket: Lwt_unix.file_descr;
  ic: Lwt_io.input_channel;
  oc: Lwt_io.output_channel;
  addr: Unix.sockaddr;
}

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable current_client : client_connection option }

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
  Lwt.return
    { socket
    ; address
    ; current_client = None }

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
    | Some client_connection ->
      let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_connection.socket in
      let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_connection.socket in
      Lwt.join [Lwt_io.close ic; Lwt_io.close oc; Lwt_unix.close client_connection.socket]
    | None -> Lwt.return_unit
  in
  cleanup

let accept_connections server =
  let rec accept_loop () =
    Lwt.catch
      (fun () ->
        Logs.debug (fun m -> m "Waiting for client connection...");
        Lwt_unix.accept server.socket >>= fun (client_sock, client_addr) ->
        let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_sock in
        let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_sock in
        let client = {
          socket = client_sock;
          addr = client_addr;
          ic;
          oc
        } in

        server.current_client <- Some client;
        Logs.debug (fun m -> m "Client registered in server state");

        Lwt.finalize
          (fun () ->
            Lwt.catch
              (fun () ->
                handle_client ic oc client_addr >>= fun () ->
                Logs.debug (fun m -> m "Client handling completed normally");
                Lwt.return_unit)
              (fun e ->
                match e with
                | End_of_file ->
                    Logs.debug (fun m -> m "Client disconnected normally");
                    Lwt.return_unit
                | e ->
                    Logs.err (fun m -> m "Error handling client: %s" (Printexc.to_string e));
                    Lwt.return_unit))
          (fun () ->
            (match server.current_client with
             | Some c when c.socket = client_sock ->
                 server.current_client <- None;
                 Logs.debug (fun m -> m "Cleared client from server state")
             | _ -> ());

            Lwt.catch
              (fun () ->
                Lwt.join [
                  Lwt_io.close ic;
                  Lwt_io.close oc;
                  Lwt_unix.close client_sock
                ])
              (fun e ->
                Logs.warn (fun m -> m "Error during cleanup: %s" (Printexc.to_string e));
                Lwt.return_unit))
        >>= fun () ->
        accept_loop ())
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) ->
          Logs.info (fun m -> m "Server stopped, closing accept loop");
          Lwt.return_unit
        | e ->
          Logs.err (fun m -> m "Accept loop error: %s" (Printexc.to_string e));
          accept_loop ())
  in
  accept_loop ()

let send_message (t: client_connection) content =
  let message = Message.create (Message.Chat content) in
  Common.write_message t.oc message