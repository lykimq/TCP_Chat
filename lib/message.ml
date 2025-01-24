type message_type =
  | Chat of bytes
  | Ack of float

type t =
  { msg_type : message_type
  ; timestamp : float }

let create msg_type = {msg_type; timestamp = Unix.gettimeofday ()}

(* Helper functions for binary encoding *)
let write_float buf f =
  let bytes = Bytes.create 8 in
  Bytes.set_int64_be bytes 0 (Int64.bits_of_float f);
  Buffer.add_bytes buf bytes

let read_float bytes offset =
  let n = Bytes.get_int64_be bytes offset in
  Int64.float_of_bits n

let write_int32 buf n =
  let bytes = Bytes.create 4 in
  Bytes.set_int32_be bytes 0 n;
  Buffer.add_bytes buf bytes

let read_int32 bytes offset = Bytes.get_int32_be bytes offset

let to_bytes t =
  let buf = Buffer.create 256 in
  (* Write 8 bytes for timestamp *)
  write_float buf t.timestamp;

  begin
    match t.msg_type with
    | Ack ack_timestamp ->
      (* Write message type tag (1 byte) *)
      Buffer.add_char buf '\000';
      (* Write 8 bytes for ack timestamp *)
      write_float buf ack_timestamp
    | Chat content ->
      (* Write message type tag (1 byte) *)
      Buffer.add_char buf '\001';
      (* Write 4 bytes for content length *)
      let content_len = Bytes.length content in
      write_int32 buf (Int32.of_int content_len);
      (* Write actual content *)
      Buffer.add_bytes buf content
  end;
  Buffer.to_bytes buf

let of_bytes bytes =
  try
    let timestamp = read_float bytes 0 in
    let msg_type =
      match Bytes.get bytes 8 with
      | '\000' ->
        (* Read ACK timestamp *)
        let ack_timestamp = read_float bytes 9 in
        Ack ack_timestamp
      | '\001' ->
        (* Read content length *)
        let content_len = read_int32 bytes 9 |> Int32.to_int in
        (* Read content *)
        let content = Bytes.create content_len in
        Bytes.blit bytes 13 content 0 content_len;
        Chat content
      | _ -> raise (Invalid_argument "Invalid message type tag")
    in
    {msg_type; timestamp}
  with
  | Invalid_argument _ as e -> raise e
  | _ -> raise (Invalid_argument "Invalid message format")

(* Helper function to convert string to chat message *)
let create_chat_message str = create (Chat (Bytes.of_string str))

(* Helper function to extract string from chat message *)
let get_chat_content = function
  | {msg_type = Chat content; _} -> begin
    try Some (Bytes.to_string content) with _ -> None
  end
  | _ -> None
