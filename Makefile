.PHONY: build clean server client test setup

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

# Start client with required host and optional port
# Usage: make client host=<hostname> port=<port_number>
client: build
	@if [ -z "$(host)" ]; then \
		echo "Error: host parameter is required"; \
		echo "Usage: make client host=<hostname> [port=<port_number>]"; \
		exit 1; \
	fi
	dune exec ./bin/main.exe client $(host) $(if $(port),$(port),8080)

# Run all tests
test: build
	dune runtest --force
	@echo "All tests completed."

setup:
	opam update
	opam install . --deps-only
	@echo "Setup completed."