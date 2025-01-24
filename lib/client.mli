(** Client implementation for chat system *)

(** Client connection type containing input/output channels and socket *)
type t = {
  ic : Lwt_io.input_channel;
  oc : Lwt_io.output_channel;
  socket : Lwt_unix.file_descr
}

(** Resolve hostname to IP address
    @param host Hostname to resolve
    @return Unix inet address
    @raise Failure if hostname cannot be resolved *)
val get_addr : string -> Unix.inet_addr

(** Connect to chat server
    @param host Server hostname
    @param port Server port
    @return Connected client instance wrapped in Lwt promise *)
val connect_to_server : string -> int -> t Lwt.t

(** Handle connection to server, managing message exchange
    @param t Client connection instance
    @return Unit wrapped in Lwt promise *)
val handle_connection : t -> unit Lwt.t

(** Send message to server
    @param t Client connection instance
    @param content Message content in bytes
    @return Unit wrapped in Lwt promise *)
val send_message : t -> bytes -> unit Lwt.t

(** Start client with connection retry logic
    @param host Server hostname
    @param port Server port
    @return Unit wrapped in Lwt promise *)
val start_client : string -> int -> unit Lwt.t