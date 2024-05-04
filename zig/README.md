# Zig

## Purpose

To make it easy to compile software with Zig in Docker images. This image is built from `scratch`

## Usage

```Dockerfile
FROM your_base_image
ENV PATH=$PATH:/zig
COPY --from=tangowithfoxtrot/zig:0.12.0 /zig /zig
```

