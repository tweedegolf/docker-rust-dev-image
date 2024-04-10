FROM ghcr.io/tweedegolf/debian:bookworm

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        unzip \
        xz-utils \
        zlib1g-dev \
        libclang1 \
        clang \
        gdb \
        lldb \
        lld \
        llvm \
        cmake \
        valgrind \
        pkg-config \
        libssl-dev \
        libpq-dev \
        libsqlite3-dev \
        default-libmysqlclient-dev \
        binaryen \
        crossbuild-essential-amd64 \
        crossbuild-essential-arm64 \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) ln -s /usr/lib/x86_64-linux-gnu/libmysqlclient.so /usr/lib/x86_64-linux-gnu/libmysqlclient.so.21 ;; \
        arm64) ln -s /usr/lib/aarch64-linux-gnu/libmysqlclient.so /usr/lib/aarch64-linux-gnu/libmysqlclient.so.21 ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac


ARG RUSTUP_VERSION
ENV RUSTUP_VERSION ${RUSTUP_VERSION}

ARG RUSTUP_SHA256_AMD64
ARG RUSTUP_SHA256_ARM64

ARG RUST_VERSION
ENV RUST_VERSION ${RUST_VERSION:-stable}

ARG RUST_COMPONENTS="rustfmt clippy rust-analysis rls rust-src"

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch="x86_64-unknown-linux-gnu"; rustupSha256=${RUSTUP_SHA256_AMD64} ;; \
        arm64) rustArch="aarch64-unknown-linux-gnu"; rustupSha256=${RUSTUP_SHA256_ARM64} ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    wget -O /usr/local/bin/rustup-init "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${rustArch}/rustup-init"; \
    if [ ! -z "${rustupSha256}" ]; then \
        echo "${rustupSha256} */usr/local/bin/rustup-init" | sha256sum -c -; \
    else \
        echo "Checksum for rustup-init not verified"; \
    fi; \
    chmod +x /usr/local/bin/rustup-init; \
    rustup-init -y --no-modify-path --default-toolchain "${RUST_VERSION}"; \
    rustup target add wasm32-unknown-unknown; \
    rustup target add aarch64-unknown-linux-gnu; \
    rustup target add x86_64-unknown-linux-gnu; \
    chmod -R a+rw ${RUSTUP_HOME} ${CARGO_HOME}; \
    rm /usr/local/bin/rustup-init; \
    rustup --version; \
    cargo --version; \
    rustc --version;

ARG SCCACHE_VERSION
ENV SCCACHE_VERSION ${SCCACHE_VERSION}

ARG SCCACHE_SHA256_AMD64
ARG SCCACHE_SHA256_ARM64

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) sccacheArch="x86_64-unknown-linux-musl"; sccacheSha256=${SCCACHE_SHA256_AMD64} ;; \
        arm64) sccacheArch="aarch64-unknown-linux-musl"; sccacheSha256=${SCCACHE_SHA256_ARM64} ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    wget -O "/tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}.tar.gz" \
        "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-${sccacheArch}.tar.gz"; \
    if [ ! -z "${sccacheSha256}" ]; then \
        echo "${sccacheSha256} */tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}.tar.gz" | sha256sum -c -; \
    else \
        echo "Checksum for sccache not verified"; \
    fi; \
    cd /tmp; \
    tar xvf "/tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}.tar.gz"; \
    mv "/tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}/sccache" /usr/local/bin/sccache; \
    chmod a+x /usr/local/bin/sccache; \
    rm -rf "/tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}/"; \
    rm -rf "/tmp/sccache-v${SCCACHE_VERSION}-${sccacheArch}.tar.gz"; \
    sccache --version;

ARG CARGO_BINSTALL_VERSION
ENV CARGO_BINSTALL_VERSION ${CARGO_BINSTALL_VERSION}

ARG CARGO_BINSTALL_SHA256_AMD64
ARG CARGO_BINSTALL_SHA256_ARM64

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) cargo_binstall_arch="x86_64-unknown-linux-musl"; cargo_binstall_sha256=${CARGO_BINSTALL_SHA256_AMD64} ;; \
        arm64) cargo_binstall_arch="aarch64-unknown-linux-musl"; cargo_binstall_sha256=${CARGO_BINSTALL_SHA256_ARM64} ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    wget -O "/tmp/cargo-binstall-$cargo_binstall_arch.tgz" \
        "https://github.com/cargo-bins/cargo-binstall/releases/download/v${CARGO_BINSTALL_VERSION}/cargo-binstall-$cargo_binstall_arch.tgz"; \
    if [ ! -z "${cargo_binstall_sha256}" ]; then \
        echo "${cargo_binstall_sha256} */tmp/cargo-binstall-${cargo_binstall_arch}.tgz" | sha256sum -c -; \
    else \
        echo "Checksum for cargo-binstall not verified"; \
    fi; \
    cd /tmp; \
    tar xvf "/tmp/cargo-binstall-$cargo_binstall_arch.tgz"; \
    mv /tmp/cargo-binstall /usr/local/bin/cargo-binstall; \
    chmod a+x /usr/local/bin/cargo-binstall; \
    rm -rf "/tmp/cargo-binstall-$cargo_binstall_arch.tgz"; \
    cargo binstall -V;

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) set -- --targets x86_64-unknown-linux-gnu --targets x86_64-unknown-linux-musl ;; \
        arm64) set -- --targets aarch64-unknown-linux-gnu --targets aarch64-unknown-linux-musl ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    cargo binstall "$@" --no-confirm \
        cargo-quickinstall \
        cargo-audit \
        cargo-outdated \
        cargo-bloat \
        cargo-llvm-lines \
        cargo-llvm-cov \
        cargo-watch \
        cargo-edit \
        cargo-chef \
        cargo-sweep \
        cargo-deny \
        trunk \
        mdbook \
        wasm-bindgen-cli \
        sqlx-cli \
        diesel_cli; \
    sqlx --version; \
    wasm-bindgen --version; \
    mdbook --version; \
    trunk --version; \
    cargo deny --version; \
    cargo sweep --version; \
    cargo chef --version; \
    cargo upgrade --version; \
    cargo llvm-lines --version; \
    cargo llvm-cov --version; \
    cargo bloat --version; \
    cargo outdated --version; \
    cargo audit --version; \
    diesel --version; \

ARG CARGO_UDEPS_VERSION
ENV CARGO_UDEPS_VERSION ${CARGO_UDEPS_VERSION}

ARG CARGO_UDEPS_SHA256_AMD64
ARG CARGO_UDEPS_SHA256_ARM64

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) udepsArch="x86_64-unknown-linux-musl"; udepsSha256=${CARGO_UDEPS_SHA256_AMD64} ;; \
        arm64) udepsArch="aarch64-unknown-linux-musl"; udepsSha256=${CARGO_UDEPS_SHA256_ARM64} ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    wget -O "/tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}.tar.gz" \
        "https://github.com/est31/cargo-udeps/releases/download/v${CARGO_UDEPS_VERSION}/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}.tar.gz"; \
    if [ ! -z "${udepsSha256}" ]; then \
        echo "${udepsSha256} */tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}.tar.gz" | sha256sum -c -; \
    else \
        echo "Checksum for cargo-udeps not verified"; \
    fi; \
    cd /tmp; \
    tar xvf "/tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}.tar.gz"; \
    mv "/tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}/cargo-udeps" /usr/local/cargo/bin/cargo-udeps; \
    chmod a+x /usr/local/cargo/bin/cargo-udeps; \
    rm -rf "/tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}/"; \
    rm -rf "/tmp/cargo-udeps-v${CARGO_UDEPS_VERSION}-${udepsArch}.tar.gz"; \
    cargo udeps --version;

# RUN cargo install diesel_cli --no-default-features --features "postgres sqlite"
