(* Default network settings *)
let port = 8080

let default_host = "127.0.0.1"

(* Reconnection settings *)
let reconnect_delay = 5.0 (* Delay between reconnection attempts in seconds *)

(* Server settings *)
let max_connections = 1
(* strictly one client base on the requirement, server only handle one client at
   a time *)

let max_retry_attempts = 5

let max_delay = 30.0 (* Maximum delay between retries in seconds *)
