open Cmdliner

type role = Server | Client

let role =
  let doc = "Specify the role (server or client)." in
  Arg.(
    required
    & pos 0 (some (enum [ ("server", Server); ("client", Client) ])) None
    & info [] ~docv:"ROLE" ~doc)

let server_addr =
  let doc = "Server address." in
  Arg.(
    value & opt string "localhost"
    & info [ "s"; "server-addr" ] ~docv:"ADDR" ~doc)

let port =
  let doc = "Port number." in
  Arg.(value & opt int 9000 & info [ "p"; "port" ] ~docs:"PORT" ~doc)

let start_client server_addr port =
  Logs.info (fun m -> m "Starting client ...");
  Lwt_main.run (Client.run_client server_addr port)

let start_server () =
  Logs.info (fun m -> m "Starting server ...");
  let sock = Server.create_socket () in
  let serve = Server.create_server sock in
  Lwt_main.run @@ serve ()

let parse_command_line role server_addr port =
  match role with
  | Server -> ("server", server_addr, port)
  | Client -> ("client", server_addr, port)

let main role server_addr port =
  let () = Logs.set_reporter (Logs.format_reporter ()) in
  let () = Logs.set_level (Some Logs.Info) in
  let role, server_addr, port = parse_command_line role server_addr port in
  match role with
  | "server" -> start_server ()
  | "client" -> start_client server_addr port
  | _ ->
      Logs.err (fun m ->
          m "Error: Invalid role specified. Use 'server' or 'client'.\n");
      exit 1

let cmd =
  let doc = "A simple server-client application." in
  let exits = Cmd.Exit.defaults in
  let man =
    [
      `S "DESCRIPTION";
      `P "This program starts either a server or a client.";
      `S "USAGE";
      `P "$(tname) $(i, ROLE) [$(i, SERVER_ADDR) $(i, PORT)]";
      `S "OPTIONS";
      `P "$(b, ROLE) can be either 'server' or 'client'.";
      `P
        "$(b, SERVER_ADDR) specifies the server address. Default is \
         'localhost'.";
      `P "$(b, PORT) specifies the port number. Default is 9000.";
      `S "EXAMPLES";
      `P "$(tname) server                 # Start the server";
      `P
        "$(tname) client localhost 9000  # Connect to server at localhost on \
         port 9000";
    ]
  in
  let term = Term.(const main $ role $ server_addr $ port) in
  Cmd.v (Cmd.info "server-client" ~doc ~exits ~man) term

let () = exit (Cmd.eval cmd)
