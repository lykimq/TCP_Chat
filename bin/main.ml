(* Function to parse command line arguments *)
let parse_command_line () =
  match Array.length Sys.argv with
  | 2 ->
      let role = Sys.argv.(1) in
      if role = "server" then ("server", "localhost", Server.port)
      else if role = "client" then (
        Logs.err (fun m -> m "Error: Server address and port not provided.");
        Logs.err (fun m ->
            m "Usage: %s <server|client> <server_address> <port>\n" Sys.argv.(0));
        exit 1)
      else (
        Logs.err (fun m ->
            m "Error: Invalid role specified. Use 'server' or 'client'.\n");
        exit 1)
  | 4 ->
      let role = Sys.argv.(1) in
      let server_addr = Sys.argv.(2) in
      let port_str = Sys.argv.(3) in
      let port_num = int_of_string port_str in
      if port_num < 0 || port_num > 65535 then (
        Logs.err (fun m -> m " Error: Invalid port number: %s" port_str);
        exit 1)
      else (role, server_addr, port_num)
  | _ ->
      Logs.err (fun m -> m "Usage: %s <server|client>\n" Sys.argv.(0));
      exit 1

let start_client server_addr port =
  Logs.info (fun m -> m "Starting client ...");
  Lwt_main.run (Client.run_client server_addr port)

let start_server () =
  Logs.info (fun m -> m "Starting server ...");
  let sock = Server.create_socket () in
  let serve = Server.create_server sock in
  Lwt_main.run @@ serve ()

let main () =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in
  let role, server_addr, port = parse_command_line () in
  match role with
  | "server" -> start_server ()
  | "client" -> start_client server_addr port
  | _ ->
      Logs.err (fun m ->
          m "Error: Invalid role specified. Use 'server' or 'client'.\n";
          exit 1)

let () = main ()
