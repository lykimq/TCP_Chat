open Lwt.Infix

let read_message ic =
  let buffer = Bytes.create Config.buffer_size in
  Lwt.catch
    (fun () ->
      Lwt_io.read_into ic buffer 0 Config.buffer_size >>= fun bytes_read ->
      if bytes_read = 0
      then Lwt.return_none
      else
        let trimmed_buffer = Bytes.sub buffer 0 bytes_read in
        Lwt.return (Some (Message.of_bytes trimmed_buffer)) )
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_none | e -> Lwt.fail e
      )

let write_message oc message =
  let bytes = Message.to_bytes message in
  Lwt.catch
    (fun () -> Lwt_io.write_from_exactly oc bytes 0 (Bytes.length bytes))
    (function
      | Unix.Unix_error (Unix.EBADF, _, _) -> Lwt.return_unit | e -> Lwt.fail e
      )

let calculate_rtt send_time =
  (Unix.gettimeofday () -. send_time) *. 1000.0 (* Convert to milliseconds *)
