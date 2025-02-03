open TCP_Chat
open Lwt.Infix

let setup_logging () =
  Logs.set_reporter (Logs.format_reporter ());
  Logs.set_level (Some Logs.Info)

let print_usage () =
  Printf.printf "Usage:\n";
  Printf.printf " As server: %s server [port]\n" Sys.argv.(0);
  Printf.printf " As client: %s client <host> [port]\n" Sys.argv.(0);
  exit 1

let parse_port default_port = function
  | None -> default_port
  | Some port_str -> (
    try int_of_string port_str
    with _ ->
      Printf.printf "Invalid port number: %s\n" port_str;
      exit 1 )

let () =
  setup_logging ();

  let mode, host, port =
    match Array.to_list Sys.argv with
    | [] | [_] -> print_usage ()
    | _ :: "server" :: port_opt :: _ ->
      (`Server, Config.default_host, parse_port Config.port (Some port_opt))
    | [_; "server"] -> (`Server, Config.default_host, Config.port)
    | _ :: "client" :: host :: port_opt :: _ ->
      (`Client, host, parse_port Config.port (Some port_opt))
    | [_; "client"; host] -> (`Client, host, Config.port)
    | _ -> print_usage ()
  in
  let main_thread =
    match mode with
    | `Server -> Server.create_server port >>= fun server ->
      Server.accept_connections server >>= fun () -> Lwt.return_unit
    | `Client -> Client.start_client host port
  in
  Lwt_main.run main_thread

