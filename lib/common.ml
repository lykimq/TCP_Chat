open Lwt.Infix

let read_message ic =
  Lwt.catch
    (fun () ->
      let len_bytes = Bytes.create 4 in
      Lwt_io.read_into_exactly ic len_bytes 0 4 >>= fun () ->
      let len = Bytes.get_int32_be len_bytes 0 |> Int32.to_int in
      let bytes = Bytes.create len in
      Lwt_io.read_into_exactly ic bytes 0 len >>= fun () ->
      Lwt.return_some (Message.of_bytes bytes) )
    (function End_of_file -> Lwt.return_none | e -> Lwt.fail e)

let write_message oc message =
  let bytes = Message.to_bytes message in
  let len = Bytes.length bytes in
  let len_bytes = Bytes.create 4 in
  Bytes.set_int32_be len_bytes 0 (Int32.of_int len);
  Lwt_io.write_from_exactly oc len_bytes 0 4 >>= fun () ->
  Lwt_io.write_from_exactly oc bytes 0 len

(* Calculate round-trip time in milliseconds *)
let calculate_rtt send_time = (Unix.gettimeofday () -. send_time) *. 1000.0

(* Format network address to string *)
let format_addr = function
  | Unix.ADDR_INET (addr, _) -> Unix.string_of_inet_addr addr
  | _ -> Unix.string_of_inet_addr Unix.inet_addr_loopback

(* Handle incoming chat message and display it *)
let handle_message_content content addr_str =
  Printf.printf "\nReceived from %s: %s\n> " addr_str (Bytes.to_string content);
  flush stdout

(* Handle acknowledgment message and display RTT *)
let handle_ack timestamp =
  let rtt = calculate_rtt timestamp in
  Printf.printf "\nMessage acknowledged (RTT: %.2f ms)\n> " rtt;
  flush stdout

(* Process user input and send message *)
let handle_input oc input =
  if input = "/quit"
  then Lwt.return_unit
  else
    let message = Message.create (Message.Chat (Bytes.of_string input)) in
    write_message oc message >>= fun () ->
    Printf.printf "> ";
    flush stdout;
    Lwt.return_unit

(* Main message receiving loop *)
let rec message_loop ic oc addr_str =
  read_message ic >>= function
  | None ->
    Logs.info (fun m -> m "Peer disconnected");
    Lwt.return_unit
  | Some message -> (
    match message.Message.msg_type with
    | Message.Chat content ->
      handle_message_content content addr_str;
      let ack = Message.create (Message.Ack message.timestamp) in
      write_message oc ack >>= fun () -> message_loop ic oc addr_str
    | Message.Ack timestamp ->
      handle_ack timestamp;
      message_loop ic oc addr_str )

(* Main input reading loop *)
let rec input_loop oc =
  Lwt_io.read_line Lwt_io.stdin >>= fun input ->
  handle_input oc input >>= fun () ->
  if input <> "/quit" then input_loop oc else Lwt.return_unit

(* Main connection handler that manages both input and message loops *)
let handle_connection ic oc addr_str =
  Lwt.pick [message_loop ic oc addr_str; input_loop oc]
