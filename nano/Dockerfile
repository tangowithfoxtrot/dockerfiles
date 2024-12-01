# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all

FROM alpine/git:latest AS git
ARG VERSION=v8.2
RUN --mount=type=ssh \
  git clone https://git.savannah.gnu.org/git/nano.git /nano && \
  cd /nano && \
  git checkout ${VERSION} || git checkout v${VERSION}

FROM --platform=$BUILDPLATFORM ubuntu:latest AS builder
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get install -y \
  autoconf \
  automake \
  autopoint \
  gcc \
  gettext \
  git \
  groff \
  libncurses-dev \
  make \
  texinfo \
  pkg-config && \
  rm -rf /var/lib/apt/lists/*

COPY --from=git /nano /nano
WORKDIR /nano

RUN ./autogen.sh CFLAGS="-O2 -Wall --static" && \
  ./configure CFLAGS="-O2 -Wall --static" && \
  make

RUN ldd ./src/nano 2>&1 | grep 'not a dynamic executable' || exit 1
RUN strip ./src/nano

FROM tangowithfoxtrot/devcontainer AS dev
USER root:root
RUN for bin in $(which -a nano); do rm -f "$bin"; done
USER ned:ned

COPY --from=builder /nano/src/nano /bin/nano
COPY --from=builder /usr/share/terminfo /usr/share/terminfo
ENTRYPOINT [ "fish" ]

FROM scratch AS release
COPY --from=builder /nano/src/nano /bin/nano
COPY --from=builder /usr/share/terminfo /usr/share/terminfo
ENTRYPOINT [ "/bin/nano" ]

FROM release
