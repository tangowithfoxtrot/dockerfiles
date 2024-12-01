# Version Fetcher

## Purpose

Fetch the latest version of various tools we want to build images for.

## Usage

### Running interactively

```bash
context="$(git rev-parse --show-toplevel)"
docker run --rm -it --mount type=bind,source="$context",target=/build_contexts version-fetcher
```
