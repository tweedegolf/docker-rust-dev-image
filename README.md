# Rust development Docker images
This development image contains a Rust compiler toolchain and a C/C++ compiler
toolchain. It also includes debugging and analysis tools such as lldb, gdb and
valgrind. This image is intended for development only. For production use-cases
you should just start with the base debian image and add your compiled binaries
to it (and install any optional library dependencies). Currently these versions
are supported:

* Rust stable: `stable` (`ghcr.io/tweedegolf/rust-dev:stable`)
* Rust 1.77: `1.77`, `latest` (`ghcr.io/tweedegolf/rust-dev:1.77`)
* Rust 1.76: `1.76` (`ghcr.io/tweedegolf/rust-dev:1.76`)
* Rust beta: `beta` (`ghcr.io/tweedegolf/rust-dev:beta`)
* Rust nightly: `nightly` (`ghcr.io/tweedegolf/rust-dev:nightly`)

Furthermore, each version also has a `-node` variant that includes the latest
LTS release of node.js and yarn.

## Usage in docker compose

```yaml
services:
    # ...
    app:
        image: ghcr.io/tweedegolf/rust-dev:stable
        # You will have to define the USER_ID and GROUP_ID environment variables
        # as `export USER_ID=$(id -u)` and `export GROUP_ID=$(id -g)` if they
        # have not already been defined previously
        user: "$USER_ID:$GROUP_ID"
        volumes: [.:/app]
        # Change to whatever command you wish to use instead of cargo watch
        command: [cargo, watch, -x, "run"]
        working_dir: /app
        environment:
            # This allows sharing cargo download even across multiple containers
            CARGO_HOME: ".cargo"
            # Create a separate target dir inside the container to prevent
            # waiting for rust-analyzer on your host
            CARGO_TARGET_DIR: "target-docker"
        # Optionally define some ports to use externally
        ports: ["127.0.0.1:8000:8000"]

    # ...
