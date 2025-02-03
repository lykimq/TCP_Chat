# TCP Chat

A robust TCP-based chat application implemented in OCaml that enables real-time communication between a server and client with message acknowledgment functionality.

## Features

- **Dual-Mode Operation**
  - Server mode: Accepts incoming client connections
  - Client mode: Connects to a specified server via IP/hostname

- **Real-Time Communication**
  - Bidirectional messaging between server and client
  - Automatic message acknowledgment system
  - Round-trip time (RTT) measurement for each message

- **Robust Architecture**
  - Asynchronous I/O using Lwt
  - Clean shutdown handling
  - Protocol-agnostic message handling (supports any byte values/encodings)
  - Single client per server design

## Prerequisites

- Linux operating system
- OCaml compiler
- OPAM (OCaml package manager)

## Installation

```bash
# Install dependencies
make setup

# Build the application
make build
```

## Usage

### Starting the Server
For simplicity the server host is always localhost. And client will connect to it.

```bash
# Default port (8080)
make server

# Custom port
make server port=3000
```

### Starting the Client

```bash
# Connect to server host=localhost and port=8080
make client

# Custom port
make client port=3000
```

### Running Tests

```bash
make test
```
