FROM --platform=linux/amd64 rust:latest as builder
# can't compile a native aarch64 binary, but zig is literally magic,
#   so the bin will work even if you run on aarch64 

ARG TARGETPLATFORM
ARG VERSION
ENV PATH=$PATH:/zig
ENV CC="zig cc"
WORKDIR /app

# install zig
COPY --from=tangowithfoxtrot/zig:latest /zig /zig

RUN git clone https://github.com/helix-editor/helix.git && \
  cd helix && \
  git checkout ${VERSION}

RUN cargo install --locked cargo-zigbuild

WORKDIR /app/helix

RUN rustup target add x86_64-unknown-linux-musl && \
  cargo zigbuild --release --target x86_64-unknown-linux-musl && \
  mv ./target/x86_64-unknown-linux-musl/release ./target/release

RUN strip ./target/release/release/hx

FROM scratch
ARG TARGETPLATFORM

# copy bin
COPY --from=builder /app/helix/target/release/release/hx /bin/hx

ENTRYPOINT [ "/bin/hx" ]

