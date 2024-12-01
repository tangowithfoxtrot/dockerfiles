# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all
ARG VERSION=0.0.1

FROM alpine:latest AS release
ENV TERM=xterm-256color

RUN apk add --no-cache bash ca-certificates git jq ncurses

COPY --from=tangowithfoxtrot/curl /bin/curl /usr/bin/curl

COPY --chmod=755 ./version-fetcher/entrypoint.sh /entrypoint.sh
RUN --mount=type=bind,target=/build_contexts,readwrite \
  /entrypoint.sh --update

FROM release
