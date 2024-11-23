# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all

FROM --platform=$BUILDPLATFORM ubuntu:latest AS builder
ARG TARGETPLATFORM
ARG VERSION
WORKDIR /app

RUN apt-get update && \
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
  pkg-config \
  texinfo

RUN git clone git://git.savannah.gnu.org/nano.git && \
  cd nano && \
  git checkout v${VERSION}

WORKDIR /app/nano

RUN ./autogen.sh CFLAGS="-O2 -Wall --static" && \
  ./configure CFLAGS="-O2 -Wall --static" && \
  make

RUN ldd ./src/nano 2>&1 | grep 'not a dynamic executable' || exit 1

RUN strip ./src/nano

FROM scratch
ARG TARGETPLATFORM

# copy bin
COPY --from=builder /app/nano/src/nano /bin/nano

# copy terminfo
COPY --from=builder /usr/share/terminfo /usr/share/terminfo

ENTRYPOINT [ "/bin/nano" ]
