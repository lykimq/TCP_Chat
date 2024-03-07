open Lwt

(* Function to parse command line arguments *)
let parse_command_line () =
  match Array.length Sys.argv with
  | 3 -> (
      let server_addr = Sys.argv.(1) in
      let port_str = Sys.argv.(2) in
      let port_num = int_of_string port_str in
      try
        if port_num < 0 || port_num > 65535 then (
          Printf.printf "Error: Invalid port number: %s\n" port_str;
          exit 1)
        else (server_addr, port_num)
      with Failure _ ->
        Printf.printf "Error: Failed to parse port number: %s\n" port_str;
        exit 1)
  | _ ->
      Printf.printf "Usage: %s <server_address> <port>\n" Sys.argv.(0);
      exit 1

(* Function to handle message communication *)
let handle_message ic oc msg =
  let open Lwt.Infix in
  Lwt_io.write_line oc msg >>= fun () ->
  Lwt_io.read_line ic >>= fun response ->
  Logs_lwt.info (fun m -> m "Server response: %s" response) >>= fun () ->
  return_unit

(* Function to send messages from stdin *)
let send_messages ic oc =
  let rec send_messages_loop () =
    Lwt_io.read_line_opt Lwt_io.stdin >>= function
    | Some msg -> handle_message ic oc msg >>= fun () -> send_messages_loop ()
    | None ->
        Logs_lwt.info (fun m -> m "End of input, closing connection.")
        >>= fun () ->
        Lwt_io.close oc >>= fun () -> return_unit
  in
  send_messages_loop ()

(* Function to establish connection to the server *)
let connect_to_server server_addr port =
  let open Lwt.Infix in
  Lwt_unix.getaddrinfo server_addr (string_of_int port)
    [ Unix.AI_SOCKTYPE Unix.SOCK_STREAM ]
  >>= function
  | [] ->
      Printf.printf "Error: No address found for: %s\n" server_addr;
      exit 1
  | ai :: _ ->
      let sockaddr = ai.Unix.ai_addr in
      let socket =
        Lwt_unix.socket ai.Unix.ai_family ai.Unix.ai_socktype
          ai.Unix.ai_protocol
      in
      Lwt.catch
        (fun () ->
          Lwt_unix.connect socket sockaddr >>= fun () ->
          let ic = Lwt_io.of_fd ~mode:Lwt_io.input socket in
          let oc = Lwt_io.of_fd ~mode:Lwt_io.output socket in
          return (Some (ic, oc)))
        (fun ex ->
          Lwt_unix.close socket >>= fun () ->
          Printf.printf "Error: Failed to connect to server: %s\n"
            (Printexc.to_string ex);
          exit 1)

let run_client server_addr port =
  let open Lwt.Infix in
  connect_to_server server_addr port >>= function
  | None -> Lwt.return_unit
  | Some (ic, oc) ->
      Lwt.finalize
        (fun () -> send_messages ic oc)
        (fun () -> Lwt_io.close ic >>= fun () -> Lwt_io.close oc)

let main () =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in
  let server_addr, port = parse_command_line () in
  Lwt_main.run (run_client server_addr port)

let () = main ()
