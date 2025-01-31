(** Server implementation for chat system *)

(** Server type containing socket and address information *)
type t =
  { socket : Lwt_unix.file_descr
  ; address : Unix.sockaddr
  ; mutable running : bool
  ; mutable current_client : Lwt_unix.file_descr option
  ; shutdown_complete : unit Lwt.u * unit Lwt.t }

(** Create a new server instance *)
val create_server : int -> t Lwt.t

(** Handle individual client connection *)
val handle_client :
  Lwt_io.input_channel ->
  Lwt_io.output_channel ->
  Unix.sockaddr ->
  unit Lwt.t

(** Start server and begin accepting connections *)
val start_server : int -> unit Lwt.t

(** Stop server and close all connections *)
val stop_server : t -> unit Lwt.t

(** Accept connections on the server *)
val accept_connections : t -> unit Lwt.t
