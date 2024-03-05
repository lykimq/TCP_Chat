open Lwt

let listening_address = Unix.inet_addr_loopback
let port = 9000
let backlog = 10

let handle_message msg oc =
  let open Lwt.Infix in
  let start_time = Unix.gettimeofday () in
  if msg = "quit" then
    Logs_lwt.info (fun m ->
        m "Received 'quit' command. Server will continue listening.")
    >>= fun () ->
    Lwt_io.close oc >>= fun () -> return `Quit
  else
    Logs_lwt.info (fun m -> m "Received message from client: %s" msg)
    >>= fun () ->
    let reply = "Message received: " ^ msg in
    Lwt_io.write_line oc reply >>= fun () ->
    let end_time = Unix.gettimeofday () in
    let roundtrip_time = end_time -. start_time in
    Logs_lwt.info (fun m ->
        m "Roundtrip time for acknowledgement: %f seconds" roundtrip_time)
    >>= fun () -> return `Continue

let rec handle_connection ic oc () =
  let open Lwt.Infix in
  Lwt_io.read_line_opt ic >>= function
  | Some msg -> (
      handle_message msg oc >>= function
      | `Quit ->
          Logs_lwt.info (fun m ->
              m "Connection closed by client (quit command)")
      | `Continue -> handle_connection ic oc ())
  | None ->
      Logs_lwt.info (fun m -> m "Connection closed by client (end of input)")

let accept_connection conn =
  let open Lwt_io in
  let fd, _ = conn in
  let ic = of_fd ~mode:input fd in
  let oc = of_fd ~mode:output fd in
  Lwt.catch
    (fun () ->
      Lwt.on_failure (handle_connection ic oc ()) (fun e ->
          Logs.err (fun m -> m "%s" (Printexc.to_string e)));
      Logs_lwt.info (fun m -> m "New connection") >>= fun () -> return_unit)
    (fun ex ->
      Logs.err (fun m ->
          m "Failed to accept connection: %s" (Printexc.to_string ex));
      (* Close the socket descriptor if there is an error *)
      Lwt_unix.close fd)
  >>= fun () -> return_unit

let rec create_socket_with_retry retries =
  if retries <= 0 then failwith "Exhausted retries, could not bind to port"
  else
    let open Lwt_unix in
    let sock = socket PF_INET SOCK_STREAM 0 in
    Lwt.catch
      (fun () ->
        (bind sock @@ ADDR_INET (listening_address, port) |> fun x -> ignore x);
        listen sock backlog;
        return sock)
      (fun ex ->
        Logs.err (fun m ->
            m "Failed to bind socket: %s" (Printexc.to_string ex));
        close sock >>= fun () ->
        sleep 1.0 >>= fun () -> create_socket_with_retry (retries - 1))
    >>= function
    | sock -> return sock

let create_socket () =
  let max_retries = 5 in
  Lwt_main.run (create_socket_with_retry max_retries)

let create_server sock =
  let rec serve () =
    Lwt_unix.accept sock >>= function
    | client, client_addr ->
        Lwt.catch
          (fun () -> accept_connection (client, client_addr) >>= serve)
          (fun ex ->
            Logs.err (fun m ->
                m "Error in connection handling: %s" (Printexc.to_string ex));
            Lwt_unix.close client >>= fun () -> serve ())
  in
  serve

let () =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in
  let sock = create_socket () in
  let serve = create_server sock in
  Lwt_main.run @@ serve ()
