open Lwt

let msg_BUFFER_SIZE = 4096

type msg_type = SEND of int | ACK of int | BAD

type msg = {
  t : msg_type;
  payload: bytes
}

let msg_type_of_string msg_type =
  match msg_type with
  | SEND length -> Printf.printf "SEND[%d]" length
  | ACK length -> Printf.printf "ACK[%d]" length
  | BAD -> Printf.printf "BAD"

