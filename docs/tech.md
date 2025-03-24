# Technical Design

## Architeture
- **Client-Server Model**: Single server handling one client connection.
- **Asynchronous I/O**: Built with Lwt for non-blocking operations (not use Threads because of the higher overhead, more complex synchronization, more resource intensive and harder to reason about).
- **Binary Protocol**: Custom message format for efficient network communication.

## Message Protocol:
```
[Header]
- 8 bytes: Timestamp (float)
- 1 byte: Message type
    - 0x00: Ack message
    - 0x01: Chat message

[Body]
For Chat:
- 4 bytes: Content length (int32)
- N bytes: Message content

For Ack:
- 8 bytes: Acknowledgement timestamp
```

## Core Components:
- **Server**: Manages TCP connections and message routing.
- **Client**: Handles user input/output and server communication.
- **Message Module**: Binary message serialization/deserialization.
- **Common Utilities**: Shared network and logging functionality

## Key Features:
- Binary message format for minimal overhead.
    + More efficient than text-based protocols (JSON/XML: more complex parsing, large message sizes, no real human-readable format).
    + Smaller message size reduces network overhead.
    + No need for string escaping/parsing.
- Fixed-size headers for fast parsing.
- Asynchronous message handling.
- Error handling.
- Connection state management.