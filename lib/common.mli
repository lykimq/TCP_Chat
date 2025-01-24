(** Common functionality for chat client and server *)

(** Read a message from the input channel
    @param ic Input channel to read from
    @return Some message if read successful, None if EOF reached *)
val read_message : Lwt_io.input_channel -> Message.t option Lwt.t

(** Write a message to the output channel
    @param oc Output channel to write to
    @param message Message to be written
    @return Unit when write is complete *)
val write_message : Lwt_io.output_channel -> Message.t -> unit Lwt.t

(** Calculate round-trip time (RTT) in milliseconds
    @param send_time The timestamp when message was sent
    @return RTT in milliseconds *)
val calculate_rtt : float -> float

(** Convert network address to string representation
    @param addr Unix socket address
    @return String representation of IP address *)
val format_addr : Unix.sockaddr -> string

(** Display received chat message with sender information
    @param content The message content in bytes
    @param addr_str The sender's address as string *)
val handle_message_content : bytes -> string -> unit

(** Display acknowledgment with round-trip time
    @param timestamp Original message timestamp for RTT calculation *)
val handle_ack : float -> unit

(** Process user input and send message to peer
    @param oc Output channel to peer
    @param input User input string
    @return Unit wrapped in Lwt promise *)
val handle_input : Lwt_io.output_channel -> string -> unit Lwt.t

(** Main message receiving loop
    @param ic Input channel from peer
    @param oc Output channel to peer
    @param addr_str Peer address string
    @return Unit wrapped in Lwt promise *)
val message_loop :
  Lwt_io.input_channel ->
  Lwt_io.output_channel ->
  string ->
  unit Lwt.t

(** Main input reading loop
    @param oc Output channel to peer
    @return Unit wrapped in Lwt promise *)
val input_loop : Lwt_io.output_channel -> unit Lwt.t

(** Main connection handler that manages both input and message loops
    Uses Lwt.pick to handle both loops concurrently
    @param ic Input channel from peer
    @param oc Output channel to peer
    @param addr_str Peer address string
    @return Unit wrapped in Lwt promise *)
val handle_connection :
  Lwt_io.input_channel ->
  Lwt_io.output_channel ->
  string ->
  unit Lwt.t
