variable "CONTAINER_REGISTRY" {
  default = "docker.io"
}

variable "CONTAINER_REGISTRY_USER" {
  default = null
}

variable "TAG" {
  type    = string
  default = "latest"
}

variable "CURL_VERSION" {
  type    = string
  default = "curl-8_11_0"
}

variable "CURL_NORMALIZED_VERSION" {
  type    = string
  default = replace(replace(CURL_VERSION, "curl-", ""), "_", ".")
}

variable "NANO_VERSION" {
  type    = string
  default = "8.2"
}

variable "NANO_NORMALIZED_VERSION" {
  type    = string
  default = replace(NANO_VERSION, "v", "")
}

variable "HELIX_VERSION" {
  type    = string
  default = "24.07"
}

variable "ZIG_VERSION" {
  type    = string
  default = "0.13.0"
}

group "default" {
  targets = [
    "curl-release",
    "devcontainer-release",
    "helix-release",
    "nano-release",
    "speedtest-release",
    "zig-release"
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
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./curl"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags = [
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/curl:${TAG}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/curl:v${CURL_NORMALIZED_VERSION}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/curl:${CURL_NORMALIZED_VERSION}"
  ]
}

# ./devcontainer
target "devcontainer-builder" {
  context    = "./devcontainer"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["devcontainer-builder"]
}

target "devcontainer-release" {
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./devcontainer"
  dockerfile = "./Dockerfile"
  target     = ""
  tags       = ["${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/devcontainer:${TAG}"]
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
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./helix"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags = [
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/helix:${TAG}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/helix:v${HELIX_VERSION}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/helix:${HELIX_VERSION}"
  ]
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
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./nano"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags = [
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/nano:${TAG}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/nano:v${NANO_NORMALIZED_VERSION}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/nano:${NANO_NORMALIZED_VERSION}"
  ]
}

# ./speedtest
target "speedtest-builder" {
  context    = "./speedtest"
  dockerfile = "./Dockerfile"
  target     = "builder"
  tags       = ["speedtest-builder"]
}

target "speedtest-release" {
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./speedtest"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags       = ["${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/speedtest:${TAG}"]
}

# # ./packages
# target "packages-depends" {
#   context    = "./packages"
#   dockerfile = "./Dockerfile"
#   target     = "builder"
#   tags       = ["packages-depends"]
# }

# target "packages-release" {
#   attest = [
#     "type=sbom,mode=max",
#     "type=provenance,mode=max"
#   ]
#   context    = "./packages"
#   dockerfile = "./Dockerfile"
#   target     = "release"
#   tags       = ["ttl.sh/packages:${TAG}"]
# }

# # ./test
# target "test-builder" {
#   context    = "./test"
#   dockerfile = "./Dockerfile"
#   target     = "user_builder"
#   tags       = ["user-builder"]
# }

# target "test-final" {
#   context    = "./test"
#   dockerfile = "./Dockerfile"
#   target     = "final"
#   tags       = ["ttl.sh/test:${TAG}"]
# }

# ./version-fetcher
# run with: `docker run --rm -it --mount type=bind,source=.,target=/build_contexts version-fetcher`
target "version-fetcher" {
  context    = "./"
  dockerfile = "./version-fetcher/Dockerfile"
  target     = "release"
  tags       = ["version-fetcher"]
}

# ./zig
target "zig-release" {
  attest = [
    "type=sbom,mode=max",
    "type=provenance,mode=max"
  ]
  context    = "./zig"
  dockerfile = "./Dockerfile"
  target     = "release"
  tags = [
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/zig:${TAG}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/zig:v${ZIG_VERSION}",
    "${CONTAINER_REGISTRY}/${CONTAINER_REGISTRY_USER}/zig:${ZIG_VERSION}"
  ]
}
