open Lwt.Infix

type t =
  { ic : Lwt_io.input_channel
  ; oc : Lwt_io.output_channel
  ; socket : Lwt_unix.file_descr }

let get_addr host =
  let host_name = Unix.gethostbyname host in
  host_name.Unix.h_addr_list.(0)

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
let send_message (t : t) content =
  let message = Message.create (Message.Chat content) in
  Common.write_message t.oc message

(* Clean shutdown handling for client connections:
   - Closes input channel
   - Closes output channel
   - Closes socket
   - Handles EBADF errors (already closed)
   - Propagates other errors for proper handling *)
let cleanup_client client =
  Lwt.catch
    (fun () ->
      Lwt.join
        [ Lwt_io.close client.ic
        ; Lwt_io.close client.oc
        ; Lwt_unix.close client.socket ] )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit | e -> Lwt.fail e
      )

(* Message receiver with clean shutdown:
   - Handles connection errors
   - Sets should_exit flag on socket closure
   - Ensures graceful termination *)
let start_receiver ~client ~should_exit =
  Lwt.catch
    (fun () -> handle_connection client)
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) ->
        should_exit := true;
        Lwt.return_unit
      | e -> Lwt.fail e )

(* User input processing with clean shutdown:
   - Checks should_exit flag for graceful termination
   - Handles /quit command
   - Ensures proper message sending before exit *)
let rec process_user_input ~client ~should_exit () =
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
      process_user_input ~client ~should_exit ()

(* Main client entry point with clean shutdown:
   - Sets up connection
   - Handles both receiver and input threads
   - Ensures cleanup on exit
   - Logs connection status *)
let start_client host port =
  Logs.info (fun m -> m "Starting client on %s:%d" host port);

  connect_to_server host port >>= fun client ->
  Logs.info (fun m ->
      m "Connected to server. Type your messages (or /quit to exit):" );
  Printf.printf "> ";
  flush stdout;

  let should_exit = ref false in
  let receiver = start_receiver ~client ~should_exit in
  let input_handler = process_user_input ~client ~should_exit () in

  Lwt.pick [receiver; input_handler] >>= fun () ->
  cleanup_client client >>= fun () ->
  Logs.info (fun m -> m "Client disconnected");
  Lwt.return_unit

(* Graceful client shutdown:
   - Sends final quit message
   - Cleans up all connections
   - Handles already closed connections
   - Logs shutdown status *)
let stop_client client =
  Logs.info (fun m -> m "Stopping client connection...");
  Lwt.catch
    (fun () ->
      (* Send a final message to indicate disconnection if needed *)
      send_message client (Bytes.of_string "/quit") >>= fun () ->
      (* Clean up the connection *)
      cleanup_client client >>= fun () ->
      Logs.info (fun m -> m "Client stopped successfully");
      Lwt.return_unit )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) ->
        (* Connection already closed, just log and continue *)
        Logs.info (fun m -> m "Client connection already closed");
        Lwt.return_unit
      | e ->
        Logs.err (fun m ->
            m "Error while stopping client: %s" (Printexc.to_string e) );
        Lwt.fail e )
