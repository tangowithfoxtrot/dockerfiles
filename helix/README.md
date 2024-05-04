# Helix Text Editor

## Purpose

To provide an easy way to use the Helix text editor on systems that don't have it available in the package manager. The binary is statically-linked, so it can be used on most Linux systems outside of Docker. This image is also built from `scratch`, making it small and relatively low-risk in terms of vulnerabilities.

## Usage

```bash
alias hx='docker run --rm -it -w /work -v "$PWD":/work -v ~/.config/helix:/home/helix/.config/helix tangowithfoxtrot/helix'
hx some_file
```

