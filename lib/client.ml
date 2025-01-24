open Lwt.Infix

type t =
  { ic : Lwt_io.input_channel
  ; oc : Lwt_io.output_channel
  ; socket : Lwt_unix.file_descr }

let get_addr host =
  let he = Unix.gethostbyname host in
  he.Unix.h_addr_list.(0)

(* Connect to server *)
let connect_to_server host port =
  let addr =
    try get_addr host
    with Not_found ->
      Logs.err (fun m -> m "Could not resolve hostname: %s" host);
      raise (Failure ("Could not resolve hostname: " ^ host))
  in
  let addr = Unix.ADDR_INET (addr, port) in
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Lwt_unix.connect socket addr >>= fun () ->
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket in
  Lwt.return {ic; oc; socket}

(* Handle connection to server *)
let handle_connection t = Common.handle_connection t.ic t.oc "server"

(* Send message to server *)
let send_message t content =
  let message = Message.create (Message.Chat content) in
  Common.write_message t.oc message

(* Main client entry point *)
let start_client host port =
  Logs.info (fun m -> m "Starting client on %s:%d" host port);

  let rec connect_with_retry () =
    Lwt.catch
      (fun () -> connect_to_server host port)
      (function
        | Unix.Unix_error (Unix.ECONNREFUSED, _, _) ->
          Logs.err (fun m ->
              m "Connection refused by server. Retrying in %.0f seconds..."
                Config.reconnect_delay );
          Lwt_unix.sleep Config.reconnect_delay >>= connect_with_retry
        | e ->
          Logs.err (fun m ->
              m "Failed to connect to server: %s" (Printexc.to_string e) );
          Lwt.fail e )
  in
  connect_with_retry () >>= fun client ->
  Logs.info (fun m ->
      m "Connected to server. Type your messages (or /quit to exit):" );
  Printf.printf "> ";
  flush stdout;

  let should_exit = ref false in

  (* Start message receiver in background *)
  let receiver =
    Lwt.catch
      (fun () -> handle_connection client)
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) ->
          should_exit := true;
          Lwt.return_unit
        | e -> Lwt.fail e )
  in

  (* Handle user input *)
  let rec input_loop () =
    if !should_exit
    then Lwt.return_unit
    else
      Lwt_io.read_line Lwt_io.stdin >>= fun input ->
      if input = "/quit"
      then (
        should_exit := true;
        Lwt.return_unit )
      else
        send_message client (Bytes.of_string input) >>= fun () ->
        Printf.printf "> ";
        flush stdout;
        input_loop ()
  in

  Lwt.pick [receiver; input_loop ()] >>= fun () ->
  (* Cleanup *)
  Lwt.catch
    (fun () ->
      Lwt.join
        [ Lwt_io.close client.ic
        ; Lwt_io.close client.oc
        ; Lwt_unix.close client.socket ] )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit | e -> Lwt.fail e
      )
  >>= fun () ->
  Logs.info (fun m -> m "Client disconnected");
  Lwt.return_unit
