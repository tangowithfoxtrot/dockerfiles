#!/bin/sh
FORMAT=${FORMAT:-json} # csv, tsv, json, jsonl, json-pretty
UNIT=${UNIT:-Mbps} # Kbps, Mbps, Gbps
speedtest --accept-license --accept-gdpr --format="$FORMAT" --unit="$UNIT" 2>/dev/null
