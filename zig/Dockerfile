# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all

FROM --platform=$BUILDPLATFORM ubuntu:latest AS zig
ARG TARGETPLATFORM
ARG VERSION=0.14.0
WORKDIR /

RUN apt-get update && \
  apt-get install -y \
  wget \
  xz-utils

RUN wget https://ziglang.org/download/${VERSION}/zig-linux-$(uname -m)-${VERSION}.tar.xz -O zig.tar.xz && \
  mkdir -p zig && tar xvf zig.tar.xz --strip-components=1 -C zig

FROM scratch AS release

# copy zig
COPY --from=zig /zig /zig
USER 65534:65534

FROM release
