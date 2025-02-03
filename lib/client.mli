(** Client implementation for chat system *)

type t =
  { ic : Lwt_io.input_channel
  ; oc : Lwt_io.output_channel
  ; socket : Lwt_unix.file_descr }
(** Client connection type containing input/output channels and socket *)

val connect_to_server : string -> int -> t Lwt.t
(** Connect to chat server *)

val send_message : t -> bytes -> unit Lwt.t
(** Send message to server *)

val start_client : string -> int -> unit Lwt.t
(** Start client with connection retry logic *)

val stop_client : t -> unit Lwt.t
(** Stop client gracefully *)

val cleanup_client : t -> unit Lwt.t
