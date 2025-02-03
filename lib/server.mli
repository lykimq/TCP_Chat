(** Server implementation for chat system *)

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable current_client : (Lwt_io.output_channel * Unix.sockaddr) option }

val create_server : int -> t Lwt.t

val handle_client :
  Lwt_io.input_channel -> Lwt_io.output_channel -> Unix.sockaddr -> unit Lwt.t

val stop_server : t -> unit Lwt.t

val accept_connections : t -> unit Lwt.t

val send_message : t -> Bytes.t -> unit Lwt.t