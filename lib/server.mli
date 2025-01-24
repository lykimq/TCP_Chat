(** Server implementation for chat system *)

(** Server type containing socket and address information *)
type t = {
  socket : Lwt_unix.file_descr;
  address : Unix.sockaddr
}

(** Create a new server instance
    @param port Port number to listen on
    @return Server instance wrapped in Lwt promise *)
val create_server : int -> t Lwt.t

(** Handle individual client connection
    @param ic Input channel from client
    @param oc Output channel to client
    @param client_addr Client's address
    @return Unit wrapped in Lwt promise *)
val handle_client :
  Lwt_io.input_channel ->
  Lwt_io.output_channel ->
  Unix.sockaddr ->
  unit Lwt.t

(** Start server and begin accepting connections
    @param port Port number to listen on
    @return Unit wrapped in Lwt promise *)
val start_server : int -> unit Lwt.t
