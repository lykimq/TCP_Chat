.PHONY: build clean server client test setup fmt

# Default build
build:
	dune build

# Clean build artifacts
clean:
	dune clean

# Start server with optional port
# Usage: make server port=<port_number>
server: build
	dune exec ./bin/main.exe server $(if $(port),$(port),8080)

# Start client with optional host and port
# Usage: make client [host=<hostname>] [port=<port_number>]
client: build
	dune exec ./bin/main.exe client $(if $(host),$(host),localhost) $(if $(port),$(port),8080)

# Run all tests
test: build
	dune runtest --force
	@echo "All tests completed."

setup:
	opam update
	opam install . --deps-only --with-test
	@echo "Setup completed."

fmt:
	dune build @fmt --auto-promote

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  build: Build the application"
	@echo "  clean: Clean build artifacts"
	@echo "  server [port=<port_number>]: Start server with optional port"
	@echo "  client [host=<hostname>] [port=<port_number>]: Start client with optional host and port"
	@echo "  test: Run all tests"
	@echo "  setup: Install dependencies"
	@echo "  fmt: Format the code"
	@echo "  help: Display this help message"
