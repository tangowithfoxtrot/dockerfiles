# syntax=docker/dockerfile-upstream:master-labs
# check=experimental=all

FROM gists/speedtest-cli:latest AS builder
ARG TARGETPLATFORM
RUN mkdir /lib-sh
RUN ldd /bin/sh | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % cp % /lib-sh

FROM alpine:latest AS user_builder
RUN addgroup -S speedtest && adduser -S speedtest -G speedtest
USER speedtest:speedtest

FROM scratch AS release
ARG TARGETPLATFORM

ENV PATH=/:/bin:/usr/local/bin
ENV FORMAT=
# csv, tsv, json, jsonl, json-pretty
ENV UNIT=
# Mbps, Kbps, Mbps, Gbps

COPY ./entrypoint.sh /entrypoint.sh
COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /lib-sh /lib
COPY --from=builder /usr/local/bin/speedtest /speedtest
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=user_builder /etc/passwd /etc/passwd
COPY --from=user_builder /etc/group /etc/group
COPY --from=user_builder /etc/shadow /etc/shadow
COPY --from=user_builder /home/speedtest /home/speedtest

USER speedtest:speedtest
ENTRYPOINT ["/entrypoint.sh"]

FROM release
