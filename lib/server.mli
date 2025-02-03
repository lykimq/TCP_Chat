(** Server implementation for chat system *)

type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable current_client : (Lwt_io.output_channel * Unix.sockaddr) option }
(** Server type containing socket and address information *)

val create_server : int -> t Lwt.t
(** Create a new server instance *)

val handle_client :
  Lwt_io.input_channel -> Lwt_io.output_channel -> Unix.sockaddr -> unit Lwt.t
(** Handle individual client connection *)

val stop_server : t -> unit Lwt.t
(** Stop server and close all connections *)

val accept_connections : t -> unit Lwt.t
(** Accept connections on the server *)

val send_message : t -> Bytes.t -> unit Lwt.t
(** Send message to client, only use for testing purposes *)
