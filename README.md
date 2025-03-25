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

### Technical Design Choices and Alternatives

#### 1. Asynchronous I/O with Lwt
**Chosen**: Lwt (Lightweight Threads) for asynchronous operations

**Alternatives Considered**:
- **Native Threads**: Rejected due to higher overhead (each thread needs it own stack (1MB+)), complex synchronization (need mutexes, conditions, etc.), and resource intensity (many threads = high memory usage)
- **Event-driven with callbacks**: Rejected due to callback hell (make code hard to read) and harder error handling (errors need to be propagated through each callback).
- **Why Lwt**: Provides cooperative multitasking with lower overhead, simpler error handling, and better resource utilization

#### 2. Binary Protocol Design
**Chosen**: Custom binary message format
**Alternatives Considered**:
- **JSON/XML**: Rejected due to larger message sizes, complex parsing, and unnecessary overhead
  Example of same message in different formats:
  ```
  // Current Binary Format (13 bytes):
  [8 bytes timestamp][1 byte type][4 bytes length] = 13 bytes total

  // JSON (100+ bytes):
  {
    "timestamp": 1234567890.123,
    "type": "chat",
    "content": "Hello"
  }

  // XML (120+ bytes):
  <message>
    <timestamp>1234567890.123</timestamp>
    <type>chat</type>
    <content>Hello</content>
  </message>
  ```
  Problems with JSON/XML:
  - **Large Message Size**: 8-10x larger than binary format
  - **String Overhead**: All numbers converted to strings
  - **Parsing Complexity**: Need full parser implementation
  - **Memory Usage**: More memory needed for string representations
  - **CPU Usage**: String operations and parsing are expensive

- **Why Binary**:
  - Minimal overhead with fixed-size headers
  - No string escaping/parsing needed
  - Smaller message size reduces network bandwidth
  - Direct memory manipulation for better performance
  - Simple implementation without external dependencies

#### 3. Fixed-Size Headers
**Chosen**: Fixed-size message headers (9 bytes)
**Alternatives Considered**:
- **Variable-length Headers**: Rejected due to complex parsing and potential buffer overflow risks
  Example of problematic variable-length header:
  ```
  "Content-Length: 1234\r\n"  // 20 bytes
  "Type: chat\r\n"           // 12 bytes
  "Timestamp: 1234567890\r\n" // 24 bytes
  ```
  Risks:
  - **Buffer Overflow**: If header parsing code assumes max header size of 100 bytes but receives 150 bytes
  - **Complex Parsing**: Need to handle multiple delimiters (\r\n, :, etc.)
  - **Memory Management**: Dynamic allocation needed for each header
  - **Performance Impact**: String operations and memory allocations slow down processing

- **No Headers**: Rejected due to lack of message type identification and timing information
  Example of problematic no-header approach:
  ```
  "Hello, how are you?"  // How to know if this is a chat message or acknowledgment?
  ```
  Risks:
  - **Message Type Ambiguity**: No way to distinguish between different message types (chat vs. acknowledgment)
  - **Message Ordering**: No timestamp means messages could arrive out of order with no way to sort them
  - **RTT Measurement**: Impossible to measure round-trip time without timestamps
  - **Message Deduplication**: No way to detect duplicate messages
  - **Protocol Extensibility**: Can't add new message types without breaking existing clients
  - **Debugging**: Hard to trace message flow without metadata

- **Why Fixed-Size**:
  - Fast parsing with direct memory access
  - Predictable memory allocation
  - No need for complex parsing logic
  - Better performance for high-frequency messaging

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
