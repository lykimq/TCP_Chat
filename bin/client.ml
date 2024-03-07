open Lwt

(* Function to parse command line arguments *)
let parse_command_line () =
  match Array.length Sys.argv with
  | 3 ->
      let server_addr = Sys.argv.(1) in
      let port_str = Sys.argv.(2) in
      let port_num = int_of_string port_str in
      if port_num < 0 || port_num > 65535 then (
        Printf.printf "Invalid port number: %s\n" port_str;
        exit 1)
      else (server_addr, port_num)
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
  >>= fun addresses ->
  let sockaddr = List.hd addresses in
  let socket =
    Lwt_unix.socket sockaddr.Unix.ai_family sockaddr.Unix.ai_socktype
      sockaddr.Unix.ai_protocol
  in
  Lwt_unix.connect socket sockaddr.Unix.ai_addr >>= fun () ->
  let ic = Lwt_io.of_fd ~mode:Lwt_io.input socket in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.output socket in
  return (ic, oc)

let run_client server_addr port =
  let open Lwt.Infix in
  connect_to_server server_addr port >>= fun (ic, oc) -> send_messages ic oc

let main () =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in
  let server_addr, port = parse_command_line () in
  Lwt_main.run (run_client server_addr port)

let () = main ()
