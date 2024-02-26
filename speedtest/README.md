# Speedtest CLI

## Purpose

The `gists/speedtest-cli` image outputs the license to stdout, making it difficult to use in scripts. This version pipes stderr (where the CLI outputs the license) to `/dev/null` and adds the ability to specify output format and the unit of measurement.

This image is also build from `scratch`, making it smaller.

## Usage

`docker run tangowithfoxtrot/speedtest:latest`

### Optional args

```bash
FORMAT=${FORMAT:-json} # csv, tsv, json, jsonl, json-pretty
UNIT=${UNIT:-Mbps} # Kbps, Mbps, Gbps
```
