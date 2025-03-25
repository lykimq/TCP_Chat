(* Message types supported by the protocol:
   - Chat: Contains the actual message content as bytes
   - Ack: Contains a timestamp for acknowledgment *)
type message_type =
  | Chat of bytes
  | Ack of float

(* Message structure:
   - msg_type: The type of message (Chat or Ack)
   - timestamp: When the message was created (for ordering and RTT) *)
type t =
  { msg_type : message_type
  ; timestamp : float }

(* Creates a new message with current timestamp *)
let create msg_type = {msg_type; timestamp = Unix.gettimeofday ()}

(* Binary encoding helper functions *)

(* Writes a float value as 8 bytes in big-endian format
   - Converts float to 64-bit integer for storage *)
let write_float buf f =
  let bytes = Bytes.create 8 in
  Bytes.set_int64_be bytes 0 (Int64.bits_of_float f);
  Buffer.add_bytes buf bytes

(* Reads a float value from 8 bytes
   - Converts 64-bit integer back to float
   - offset: Starting position in the byte array *)
let read_float bytes offset =
  let n = Bytes.get_int64_be bytes offset in
  Int64.float_of_bits n

(* Writes a 32-bit integer as 4 bytes
   - Used for message content length *)
let write_int32 buf n =
  let bytes = Bytes.create 4 in
  Bytes.set_int32_be bytes 0 n;
  Buffer.add_bytes buf bytes

(* Reads a 32-bit integer from 4 bytes
   - Used for message content length
   - offset: Starting position in the byte array *)
let read_int32 bytes offset = Bytes.get_int32_be bytes offset

(* Serializes a message to binary format:
   Message Layout:
   [Timestamp: 8 bytes] [Message Type: 1 byte] [Message Specific Data]

   For Chat messages:
   [Timestamp: 8 bytes] [Type: 0x01] [Content Length: 4 bytes] [Content: N bytes]

   For Ack messages:
   [Timestamp: 8 bytes] [Type: 0x00] [Ack Timestamp: 8 bytes] *)
let to_bytes t =
  let buf = Buffer.create 256 in
  (* Write 8 bytes for timestamp *)
  write_float buf t.timestamp;

  begin
    match t.msg_type with
    | Ack ack_timestamp ->
      (* Write message type tag (1 byte) - 0x00 for Ack *)
      Buffer.add_char buf '\000';
      (* Write 8 bytes for ack timestamp *)
      write_float buf ack_timestamp
    | Chat content ->
      (* Write message type tag (1 byte) - 0x01 for Chat *)
      Buffer.add_char buf '\001';
      (* Write 4 bytes for content length *)
      let content_len = Bytes.length content in
      write_int32 buf (Int32.of_int content_len);
      (* Write actual content *)
      Buffer.add_bytes buf content
  end;
  Buffer.to_bytes buf

(* Deserializes binary data back into a message
   - Validates message format
   - Handles both Chat and Ack message types
   - Raises Invalid_argument for malformed messages *)
let of_bytes bytes =
  try
    (* Read timestamp from first 8 bytes *)
    let timestamp = read_float bytes 0 in
    (* Read message type from byte 8 *)
    let msg_type =
      match Bytes.get bytes 8 with
      | '\000' ->
        (* Read ACK timestamp from bytes 9-16 *)
        let ack_timestamp = read_float bytes 9 in
        Ack ack_timestamp
      | '\001' ->
        (* Read content length from bytes 9-12 *)
        let content_len = read_int32 bytes 9 |> Int32.to_int in
        (* Read content from bytes 13 onwards *)
        let content = Bytes.create content_len in
        Bytes.blit bytes 13 content 0 content_len;
        Chat content
      | _ -> raise (Invalid_argument "Invalid message type tag")
    in
    {msg_type; timestamp}
  with
  | Invalid_argument _ as e -> raise e
  | _ -> raise (Invalid_argument "Invalid message format")

(* Extracts content from a Chat message
   - Converts bytes to string
   - Raises Invalid_argument for Ack messages *)
let message_get_content msg =
  match msg.msg_type with
  | Chat content -> Bytes.to_string content
  | Ack _ -> raise (Invalid_argument "Message is an ACK, no content")
