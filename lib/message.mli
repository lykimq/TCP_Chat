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

(** Create a new message *)
val create : message_type -> t

(** Convert message to bytes for wire transmission *)
val to_bytes : t -> bytes

(** Convert bytes to message *)
val of_bytes : bytes -> t
