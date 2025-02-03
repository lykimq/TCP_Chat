(** Message encoding/decoding for chat system

    Wire format:
    | Field     | Size (bytes) | Description        |
    |-----------|--------------|--------------------|
    | Timestamp | 8            | Message timestamp  |
    | Type      | 1            | 0=Ack, 1=Chat      |
    | Length    | 4            | Content length     |
    | Content   | variable     | Message content    |
*)

type message_type =
  | Chat of bytes  (** Chat message containing content *)
  | Ack of float  (** Acknowledgment message containing original timestamp *)

type t =
  { msg_type : message_type  (** Type of the message *)
  ; timestamp : float  (** Timestamp when message was created *) }

val create : message_type -> t

val to_bytes : t -> bytes

val of_bytes : bytes -> t

val message_get_content : t -> string
