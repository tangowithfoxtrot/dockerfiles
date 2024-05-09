FROM --platform=$TARGETPLATFORM alpine:latest as builder
ARG TARGETPLATFORM
ARG VERSION=8.7.1

# the following build steps were heavily derived from:
# https://github.com/moparisthebest/static-curl

ENV CC=clang
WORKDIR /work

RUN apk add --no-cache autoconf automake build-base ca-certificates clang git libssh2-dev libssh2-static libtool m4 nghttp2-dev nghttp2-static openssl-dev perl
RUN apk add --no-cache openssl-libs-static zlib-static

RUN git clone https://github.com/curl/curl.git && \
  cd curl && \
  git checkout "$(echo curl-${VERSION//./_})"

WORKDIR /work/curl
# workdir needs to be ./curl for autoreconf to succeed
RUN autoreconf -fi

RUN LDFLAGS="-static" PKG_CONFIG="pkg-config --static" ./configure \
  --disable-shared \
  --enable-static \
  --disable-ldap \
  --enable-ipv6 \
  --enable-unix-sockets \
  --with-ssl \
  --with-libssh2 \
  --disable-docs \
  --disable-manual \
  --without-libpsl

RUN make -j$(nproc) V=1 LDFLAGS="-static -all-static"
RUN strip src/curl

FROM --platform=$TARGETPLATFORM scratch
ARG TARGETPLATFORM

COPY --from=builder /work/curl/src/curl /bin/curl
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/bin/curl"]
