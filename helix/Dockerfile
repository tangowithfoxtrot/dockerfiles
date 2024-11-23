# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all;skip=FromPlatformFlagConstDisallowed

FROM alpine/git:latest AS git
ARG VERSION=24.07
RUN --mount=type=ssh \
  git clone https://github.com/helix-editor/helix.git /helix && \
  cd /helix && \
  git checkout ${VERSION}

FROM --platform=linux/amd64 messense/cargo-zigbuild AS builder
COPY --from=git /helix /helix
WORKDIR /helix
ARG TARGET=x86_64-unknown-linux-musl

RUN mkdir -p ~/.cargo && \
  echo "[profile.release]" > ~/.cargo/config.toml && \
  echo "strip = true" >> ~/.cargo/config.toml && \
  rustup target add $TARGET && \
  cargo run --package=helix-loader --bin=hx-loader && \
  cargo zigbuild --release --locked --target "$TARGET" && \
  mv "./target/$TARGET/release" ./target/release && \
  rm -rf ./runtime/grammars/sources

FROM tangowithfoxtrot/devcontainer AS dev
ENV COLORTERM=truecolor
USER root:root
RUN for bin in $(which -a hx); do rm -f "$bin"; done
USER ned:ned

COPY --from=builder /helix/target/release/release/hx /bin/hx
COPY --from=builder /helix/runtime /usr/lib/helix/runtime
ENTRYPOINT [ "fish" ]

FROM scratch AS release
ENV COLORTERM=truecolor
ENV HOME=/home/helix

# copy bin
COPY --from=builder /helix/target/release/release/hx /bin/hx
COPY --from=builder /helix/runtime /usr/lib/helix/runtime

WORKDIR /work
ENTRYPOINT [ "/bin/hx" ]

FROM release
