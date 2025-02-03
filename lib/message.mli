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
  | Ack of float  (** Acknowledgment message containing original timestamp *)

type t =
  { msg_type : message_type  (** Type of the message *)
  ; timestamp : float  (** Timestamp when message was created *) }
(** Message record type *)

val create : message_type -> t
(** Create a new message *)

val to_bytes : t -> bytes
(** Convert message to bytes for wire transmission *)

val of_bytes : bytes -> t
(** Convert bytes to message *)

val message_get_content : t -> string
(** Get the content of a message *)
