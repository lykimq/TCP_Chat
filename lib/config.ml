(* Network configuration *)
let port = 8080

let default_host = "127.0.0.1"

let buffer_size = 1024

(* Connection settings *)
let connection_timeout = 300.0 (* 5 minutes *)

let reconnect_delay = 5.0 (* Delay between reconnection attempts *)

(* Message settings *)
let max_message_length = 4096 (* Maximum message length in bytes *)

(* Server settings *)
let max_pending_messages = 10 (* Maximum number of pending messages *)
