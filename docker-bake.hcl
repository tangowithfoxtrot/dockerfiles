variable "TTL_SH" {
  default = "24h"
}

group "default" {
  targets = [
    "curl-release",
    "devcontainer-release",
    "helix-release",
    "nano-release",
    "speedtest-release",
    "packages-release"
  ]
}

group "test" {
  targets = ["test-builder", "test-final"]
}

target "base" {
  platforms = ["linux/amd64", "linux/arm64"]
}

# ./curl
target "curl-release" {
  context    = "./curl"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["ttl.sh/curl:${TTL_SH}"]
}

# ./devcontainer
target "devcontainer-builder" {
  context    = "./devcontainer"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["devcontainer-builder"]
}

target "devcontainer-release" {
  context    = "./devcontainer"
  dockerfile = "./Dockerfile"
  target     = ""
  tags       = ["ttl.sh/devcontainer:${TTL_SH}"]
}

# ./helix
target "helix-git" {
  context    = "./helix"
  dockerfile = "./Dockerfile"
  target     = "git"
  tags       = ["helix-git"]
}

target "helix-builder" {
  context    = "./helix"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["helix-builder"]
}

target "helix-dev" {
  context    = "./helix"
  dockerfile = "./Dockerfile"
  target     = "dev"
  tags       = ["helix-dev"]
}

target "helix-release" {
  context    = "./helix"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["ttl.sh/helix:${TTL_SH}"]
}

# ./nano
target "nano-git" {
  context    = "./nano"
  dockerfile = "./Dockerfile"
  target     = "git"
  tags       = ["nano-git"]
}

target "nano-builder" {
  context    = "./nano"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["nano-builder"]
}

target "nano-dev" {
  context    = "./nano"
  dockerfile = "./Dockerfile"
  target     = "dev"
  tags       = ["nano-dev"]
}

target "nano-release" {
  context    = "./nano"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["ttl.sh/nano:${TTL_SH}"]
}

# ./speedtest
target "speedtest-builder" {
  context    = "./speedtest"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["speedtest-builder"]
}

target "speedtest-release" {
  context    = "./speedtest"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["ttl.sh/speedtest:${TTL_SH}"]
}

# ./packages
target "packages-depends" {
  context    = "./packages"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["packages-depends"]
}

target "packages-release" {
  context    = "./packages"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["ttl.sh/packages:${TTL_SH}"]
}

# ./test
target "test-builder" {
  context    = "./test"
  dockerfile = "./Dockerfile"
  target     = "user_builder"
  tags       = ["user-builder"]
}

target "test-final" {
  context    = "./test"
  dockerfile = "./Dockerfile"
  target     = "final"
  tags       = ["ttl.sh/test:${TTL_SH}"]
}

# ./version-fetcher
# run with: `docker run --rm -it --mount type=bind,source=.,target=/build_contexts version-fetcher`
target "version-fetcher" {
  context    = "./"
  dockerfile = "./version-fetcher/Dockerfile"
  target     = "release"
  tags       = ["version-fetcher"]
}
