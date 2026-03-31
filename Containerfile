# FreeSynergy packaging for Kanidm — Identity and Access Management
# Build: podman build -t ghcr.io/freesynergy/kanidm:latest .
FROM docker.io/library/rust:1-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential clang libclang-dev cmake \
    libssl-dev pkg-config libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
RUN cargo build --release -p kanidmd -p kanidm_tools

FROM docker.io/library/debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/kanidmd  /usr/local/bin/kanidmd
COPY --from=builder /build/target/release/kanidm   /usr/local/bin/kanidm

RUN useradd -r -s /bin/false kanidm && \
    mkdir -p /etc/kanidm /var/lib/kanidm && \
    chown -R kanidm:kanidm /etc/kanidm /var/lib/kanidm

VOLUME ["/etc/kanidm", "/var/lib/kanidm"]
EXPOSE 8443 3636

USER kanidm
ENTRYPOINT ["/usr/local/bin/kanidmd"]
CMD ["server", "-c", "/etc/kanidm/server.toml"]
