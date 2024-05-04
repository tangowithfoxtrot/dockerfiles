# GNU Nano

## Purpose

To try the new `--modernbindings` option. The binary is statically-linked, so it can be used on most Linux systems outside of Docker. This image is also built from `scratch`, making it small and relatively low-risk in terms of vulnerabilities.

## Usage

`docker run --rm -it -w /work -v "$PWD":/work tangowithfoxtrot/nano`

