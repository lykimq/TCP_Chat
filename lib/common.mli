(** Common functionality for chat client and server *)

val read_message : Lwt_io.input_channel -> Message.t option Lwt.t
(** Read a message from the input channel *)

val write_message : Lwt_io.output_channel -> Message.t -> unit Lwt.t
(** Write a message to the output channel *)

val calculate_rtt : float -> float
(** Calculate round-trip time (RTT) in milliseconds *)

val format_addr : Unix.sockaddr -> string

val handle_connection :
  Lwt_io.input_channel -> Lwt_io.output_channel -> string -> unit Lwt.t
(** Main connection handler that manages both input and message loops
    Uses Lwt.pick to handle both loops concurrently *)
