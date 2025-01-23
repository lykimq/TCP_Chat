open Lwt.Infix

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr }

let create_server port =
  let open Lwt_unix in
  let socket = socket PF_INET SOCK_STREAM 0 in
  setsockopt socket SO_REUSEADDR true;
  let address = Unix.ADDR_INET (Unix.inet_addr_any, port) in
  bind socket address >>= fun () ->
  listen socket Config.max_pending_messages;
  Lwt.return {socket; address}

let handle_client ic oc client_addr =
  let rec message_loop () =
    Common.read_message ic >>= function
    | None ->
      Logs.info (fun m -> m "Client disconnected normally");
      Lwt.return_unit
    | Some message -> (
      match message.Message.msg_type with
      | Message.Chat content ->
        Printf.printf "\nReceived from %s: %s\n> "
          (Unix.string_of_inet_addr
             ( match client_addr with
             | Unix.ADDR_INET (addr, _) -> addr
             | _ -> Unix.inet_addr_loopback ) )
          content;
        flush stdout;
        (* Send acknowledgement *)
        let ack = Message.create (Message.Ack message.Message.timestamp) in
        Common.write_message oc ack >>= fun () -> message_loop ()
      | Message.Ack _ -> message_loop () )
  in
  Lwt.catch
    (fun () -> message_loop ())
    (function
      | Unix.Unix_error (Unix.ECONNRESET, _, _)
      | Unix.Unix_error (Unix.EPIPE, _, _)
      | Unix.Unix_error (Unix.EBADF, _, _) ->
        Logs.info (fun m ->
            m "Client disconnected: %s"
              (Unix.string_of_inet_addr
                 ( match client_addr with
                 | Unix.ADDR_INET (addr, _) -> addr
                 | _ -> Unix.inet_addr_loopback ) ) );
        Lwt.return_unit
      | e -> Lwt.fail e )

let start_server port =
  Logs.info (fun m -> m "Starting server on port %d" port);
  create_server port >>= fun server ->
  Printf.printf "> ";
  flush stdout;

  let rec accept_loop () =
    Lwt_unix.accept server.socket >>= fun (client_socket, client_addr) ->
    Logs.info (fun m ->
        m "Accepted new connection from %s"
          (Unix.string_of_inet_addr
             ( match client_addr with
             | Unix.ADDR_INET (addr, _) -> addr
             | _ -> Unix.inet_addr_loopback ) ) );

    let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_socket in
    let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_socket in

    Lwt.async (fun () ->
        Lwt.finalize
          (fun () -> handle_client ic oc client_addr)
          (fun () ->
            Lwt.catch
              (fun () ->
                Logs.info (fun m ->
                    m "Closing connection with %s"
                      (Unix.string_of_inet_addr
                         ( match client_addr with
                         | Unix.ADDR_INET (addr, _) -> addr
                         | _ -> Unix.inet_addr_loopback ) ) );
                Lwt.join
                  [ Lwt_io.close ic
                  ; Lwt_io.close oc
                  ; Lwt_unix.close client_socket ] )
              (function
                | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit
                | e -> Lwt.fail e ) ) );
    accept_loop ()
  in
  accept_loop ()