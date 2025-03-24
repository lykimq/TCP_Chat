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

## Technical Design

### Architecture
- **Client-Server Model**: Single server handling one client connection
- **Asynchronous I/O**: Built with Lwt for non-blocking operations
- **Binary Protocol**: Custom message format for efficient network communication

### Message Protocol
```
[Header]
- 8 bytes: Timestamp (float)
- 1 byte: Message Type
  - 0x00: Ack message
  - 0x01: Chat message

[Body]
For Chat:
- 4 bytes: Content length (int32)
- N bytes: Message content

For Ack:
- 8 bytes: Acknowledgment timestamp
```

### Core Components
- **Server**: Manages TCP connections and message routing
- **Client**: Handles user input/output and server communication
- **Message Module**: Binary message serialization/deserialization
- **Common Utilities**: Shared network and logging functionality

### Key Features
- Binary message format for minimal overhead
- Fixed-size headers for fast parsing
- Asynchronous message handling
- Robust error recovery
- Connection state management

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
