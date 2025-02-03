(** Client implementation for chat system *)

type t =
  { ic : Lwt_io.input_channel
  ; oc : Lwt_io.output_channel
  ; socket : Lwt_unix.file_descr }
(** Client connection type containing input/output channels and socket *)

val connect_to_server : string -> int -> t Lwt.t

val send_message : t -> bytes -> unit Lwt.t

val start_client : string -> int -> unit Lwt.t

val stop_client : t -> unit Lwt.t

val cleanup_client : t -> unit Lwt.t
