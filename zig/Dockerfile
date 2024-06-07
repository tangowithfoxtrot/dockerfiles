FROM --platform=$BUILDPLATFORM ubuntu:latest as zig
ARG TARGETPLATFORM
ARG VERSION=0.13.0
WORKDIR /

RUN apt-get update && \
  apt-get install -y \
    wget \
    xz-utils

RUN <<eof
  case "$TARGETPLATFORM" in
    *"linux/amd64"*)
      wget https://ziglang.org/builds/zig-linux-x86_64-${VERSION}.tar.xz -O zig.tar.xz
      mkdir -p zig && tar xvf zig.tar.xz --strip-components=1 -C zig;;
    *"linux/arm64"*)
      wget https://ziglang.org/builds/zig-linux-aarch64-${VERSION}.tar.xz -O zig.tar.xz
      mkdir -p zig && tar xvf zig.tar.xz --strip-components=1 -C zig;;
    *)
      echo "Unsupported target platform: $TARGETPLATFORM";
      exit 1;;
  esac
eof

FROM scratch

# copy zig
COPY --from=zig /zig /zig

