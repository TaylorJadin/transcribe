FROM nixos/nix AS builder

WORKDIR /build
COPY flake.nix ./

RUN nix --extra-experimental-features "nix-command flakes" build \
    && mkdir /closure \
    && cp -a $(nix-store --query --requisites result) /closure/

FROM scratch

COPY --from=builder /closure/ /nix/store/
COPY --from=builder /build/result/ /runtime/

# Create and set permissions on necessary folders
RUN ["/runtime/bin/install", "-d", "-m", "1777", "/tmp", "/models"]

COPY app.sh /app/app.sh

ENV PATH=/runtime/bin \
    SSL_CERT_FILE=/runtime/etc/ssl/certs/ca-bundle.crt \
    MODEL=small.en MODEL_DIR=/models
WORKDIR /data
ENTRYPOINT ["/runtime/bin/bash", "/app/app.sh"]
