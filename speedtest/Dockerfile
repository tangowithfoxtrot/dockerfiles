FROM gists/speedtest-cli:latest as builder
ARG TARGETPLATFORM
RUN mkdir /lib-sh
RUN ldd /bin/sh | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % cp % /lib-sh

FROM scratch
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

ENTRYPOINT ["/entrypoint.sh"]
