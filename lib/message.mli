(** Message type and encoding/decoding functionality for chat system

    Message format:
    - Fixed 8 bytes for timestamp
    - 1 byte for message type tag
    - 4 bytes for content length
    - content length bytes for content

    Message type tag:
    - 1 byte for chat message
    - 0 byte for ack message

    Message structure:
    [timestamp: 8 bytes][type: 1 byte][payload ....]
    where payload for ACK: [ack_timestamp: 8 bytes]
    where payload for CHAT: [content_length: 4 bytes][content: N variable length]
*)

(** Message type variants *)
type message_type =
  | Chat of bytes  (** Chat message containing content *)
  | Ack of float   (** Acknowledgment message containing original timestamp *)

(** Message record type *)
type t = {
  msg_type : message_type;  (** Type of the message *)
  timestamp : float         (** Timestamp when message was created *)
}

(** Create a new message
    @param msg_type Type of message to create
    @return Message with current timestamp *)
val create : message_type -> t

(** Convert message to bytes for wire transmission
    @param t Message to convert
    @return Bytes representation of message *)
val to_bytes : t -> bytes

(** Convert bytes to message
    @param bytes Bytes to convert
    @return Message
    @raise Invalid_argument if bytes don't represent a valid message *)
val of_bytes : bytes -> t

(** Create a chat message from string
    @param str String content for message
    @return Message with Chat type *)
val create_chat_message : string -> t

(** Extract string content from chat message
    @param t Message to extract from
    @return Some string if message is Chat type and valid, None otherwise *)
val get_chat_content : t -> string option

