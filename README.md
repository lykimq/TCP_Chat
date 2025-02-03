# TCP_Chat

- Application should start in two modes:
    - as a server, waiting for one client to connect or;
    - as a client, taking an IP address (or hostname) of server to connect to.

- After connection is established, user on either side (server and client) can send messages to the other side.

- After connection is terminated by the client, server continues waiting for another client.

- The receiving side should acknowledge every incoming message (automatically send back a "message received" indication), sending side should show the roundtrip time for acknowledgment.

Wire protocol shouldn't make any assumptions on the message contents (e.g. allowed byte values, character encoding, etc).

UI is a choice - can be just a console.

## Requirements:

- Application is to be compiled and run on Linux
- Implementation language: OCaml
- You may use any 3rd-party general-purpose libraries (extlib, containers, lwt, etc)
- Primary objectives: robustness, code simplicity and maintainability

## Architecture
- Client-server model using OCaml with Lwt for asynchronous I/O
- TCP-based communication
- Message protocol with timestamp and acknowledgment
- Support for chat messages and acknowledgments

## Features
- Reconnection logic with exponential backoff
- Round-trip time (RTT) measurement
- Clean shutdown handling
- Message acknowledgment system
- Strictly one client at a time

## Connection Capacity
- Server can hanlde one client at a time
- Each client connect runs in its own async thread

## Build and run

```
make build

make server port=<port_number>
make client host=<hostname> port=<port_number>
```

## Test

```
make test
```
