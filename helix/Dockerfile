# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all

FROM --platform=linux/amd64 messense/cargo-zigbuild AS builder
ARG VERSION

WORKDIR /app

RUN git clone https://github.com/helix-editor/helix.git && \
  cd helix && \
  git checkout ${VERSION}

WORKDIR /app/helix

# RUN rustup target add x86_64-unknown-linux-musl && \
#   cargo zigbuild --release --target x86_64-unknown-linux-musl && \
#   mv ./target/x86_64-unknown-linux-musl/release ./target/release

RUN rustup target add x86_64-unknown-linux-musl
RUN cargo zigbuild --release --target x86_64-unknown-linux-musl && \
  mv ./target/x86_64-unknown-linux-musl/release ./target/release

RUN strip ./target/release/release/hx

FROM scratch
ENV HOME=/home/helix

# copy bin
COPY --from=builder /app/helix/target/release/release/hx /bin/hx

ENTRYPOINT [ "/bin/hx" ]

