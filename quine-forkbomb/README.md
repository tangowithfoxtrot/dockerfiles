# Quine Forkbomb

## Acknowledgements

Not my quine. Credit for that goes to: [pelmers/quine](https://github.com/pelmers/quine.git)

## Purpose

For educational purposes only. I use it to intentionally crash my own local VMs when testing stuff.

Do not upload this to container registries. Doing so could likely be a violation of ToS.

Do not run this if you don't know what you're doing.

You have been warned.

## Usage

```bash
Usage: quine-forkbomb [OPTIONS]

Options:
  --i-really-want-to-forkbomb    run parallel forks indefinitely; be careful

Example:
  docker run --name forkbomb --rm quine-forkbomb # --i-really-want-to-forkbomb
```

