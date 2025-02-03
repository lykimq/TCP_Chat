open TCP_Chat
open Alcotest

(* Message encoding tests *)
let test_message_encoding () =
  let content = "Hello, world!" |> Bytes.of_string in
  let msg = Message.create (Message.Chat content) in
  let encoded = Message.to_bytes msg in
  let decoded = Message.of_bytes encoded in
  check string "same message type"
    (match decoded.msg_type with Message.Chat c -> Bytes.to_string c | _ -> "")
    (Bytes.to_string content)

let test_ack_encoding () =
  let timestamp = Unix.gettimeofday () in
  let msg = Message.create (Message.Ack timestamp) in
  let encoded = Message.to_bytes msg in
  let decoded = Message.of_bytes encoded in
  check bool "is ack" true
    (match decoded.msg_type with Message.Ack _ -> true | _ -> false);
  check (float 0.0001) "same timestamp" timestamp
    (match decoded.msg_type with Message.Ack t -> t | _ -> 0.0)

let message_tests =
  [ test_case "message encoding/decoding" `Quick test_message_encoding
  ; test_case "acknowledge encoding/decoding" `Quick test_ack_encoding ]

let () =
  let open Alcotest in
  run "TCP Chat" [("message", message_tests)]
