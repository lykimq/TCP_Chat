(*open Data_encoding

  (* Define the encoding for messages *)
  let message_encoding = def "message" @@ obj1 (req "content" string)

  (* Encode a message to bytes *)
  let encode_message msg =
    match Json.construct message_encoding msg with
    | `String encoded -> encoded ^ "\r\n"
    | _ -> raise (Invalid_argument "Failed to encode message")


  (* Decode a message from bytes *)
  (*let decode_message bytes =
    match Json.from_string bytes with
    | Ok json ->
        Data_encoding.Json.destruct ~bson_relaxation:false message_encoding json
    | Error err ->
        let () = Printf.printf "Error parsing JSON string: %s" err in
        raise (Invalid_argument "Invalid JSON string")*)
  let decode_message bytes =
    String.trim bytes*)

open Lwt.Infix

type message = string

let read_message ic length =
  let buffer = Bytes.create length in
  Lwt_io.read_into_exactly ic buffer 0 length >>= fun () ->
  Lwt.return (Bytes.to_string buffer)

let write_message oc msg = Lwt_io.write oc msg
