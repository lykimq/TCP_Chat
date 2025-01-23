type message_type =
  | Chat of string
  | Ack of float (* Timestamp for RTT calculation *)

type t =
  { msg_type : message_type
  ; timestamp : float }

let create msg_type = {msg_type; timestamp = Unix.gettimeofday ()}

let to_bytes t =
  let msg_str =
    match t.msg_type with
    | Chat msg -> Printf.sprintf "CHAT:%s" msg
    | Ack timestamp -> Printf.sprintf "ACK:%f" timestamp
  in
  Printf.sprintf "%f|%s" t.timestamp msg_str |> Bytes.of_string

(* TODO: handle errors *)
let of_bytes bytes =
  let str = Bytes.to_string bytes in
  try
    match String.split_on_char '|' str with
    | [timestamp_str; msg_str] ->
      let timestamp = float_of_string timestamp_str in
      let msg_type =
        if String.length msg_str >= 4 && String.sub msg_str 0 4 = "ACK:"
        then
          let ack_time =
            float_of_string (String.sub msg_str 4 (String.length msg_str - 4))
          in
          Ack ack_time
        else if String.length msg_str >= 5 && String.sub msg_str 0 5 = "CHAT:"
        then Chat (String.sub msg_str 5 (String.length msg_str - 5))
        else raise (Invalid_argument "Invalid message format")
      in
      {msg_type; timestamp}
    | _ -> raise (Invalid_argument "Invalid message format")
  with _ -> raise (Invalid_argument "Invalid message format")
