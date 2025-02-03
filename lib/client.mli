(** Client implementation for chat system *)

(** Client connection type containing input/output channels and socket *)
type t = {
  ic : Lwt_io.input_channel;
  oc : Lwt_io.output_channel;
  socket : Lwt_unix.file_descr
}

(** Resolve hostname to IP address *)
val get_addr : string -> Unix.inet_addr

(** Connect to chat server *)
val connect_to_server : string -> int -> t Lwt.t

(** Handle connection to server, managing message exchange *)
val handle_connection : t -> unit Lwt.t

(** Send message to server *)
val send_message : t -> bytes -> unit Lwt.t

(** Start client with connection retry logic *)
val start_client : string -> int -> unit Lwt.t

(** Stop client gracefully *)
val stop_client : t -> unit Lwt.t

val cleanup_client : t -> unit Lwt.t
