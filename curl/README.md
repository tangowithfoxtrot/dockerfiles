# Curl

## Purpose

Curl doesn't seem to distribute statically-linked binaries officially, so this image builds it from source.

## Usage

### Running interactively

```bash
docker run --rm -it tangowithfoxtrot/curl:latest --help
```

### Using it in another docker image

```dockerfile
COPY --from=tangowithfoxtrot/curl:latest /bin/curl /usr/bin/curl
```

