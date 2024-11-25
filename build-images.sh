#!/usr/bin/env bash
# shellcheck disable=SC2155
set -eo pipefail

# env setup
find_contexts() {
  # find all directories containing a Dockerfile
  find . -type f -name Dockerfile -exec dirname {} \; | sort | sed 's|^\./||'
}

# all vars in this section must be duplicated in the do_in_docker function
BASENAME="$(basename "$0")"                                                                # name of the script
BUILD_PLATFORMS="${BUILD_PLATFORMS:-linux/amd64,linux/arm64}"                              # platforms to build for
CURL_ARGS="${CURL_ARGS:-"--header \"Authorization: Bearer $(gh auth token || echo -n)\""}" # curl arguments; try to use a GitHub token if available
CONTAINER_BUILD_CONTEXTS="${CONTAINER_BUILD_CONTEXTS:-$(find_contexts)}"                   # directories containing Dockerfiles
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-docker.io}"                                      # docker.io
CONTAINER_REPO="${CONTAINER_REPO:-$(git config user.name)}"                                # docker.io/username
CONTAINER_ENGINE_SOCKET="${CONTAINER_ENGINE_SOCKET:-/var/run/docker.sock}"                 # docker socket; only needed if running in docker
DOINDOCKER="${DOINDOCKER:-1}"                                                              # run the builds in docker
DOINDOCKER_BUILD_TOOLS="${DOINDOCKER_BUILD_TOOLS:-bash curl github-cli git jq ncurses}"    # alpine packages needed in the docker container
REGISTRY_USER="${REGISTRY_USER:-$CONTAINER_REPO}"                                          # username for the registry
REGISTRY_PAT="${REGISTRY_PAT:-$(gh auth status || echo -n)}"                               # personal access token for the registry
REPO_ROOT="$(git rev-parse --show-toplevel)"                                               # root of the repo; should never be overridden
ATTESTATION_ARGS="${ATTESTATION_ARGS:---attest type=sbom --attest type=provenance}"        # supply chain attestation arguments
VERBOSE="${VERBOSE:-0}"                                                                    # set to '1' to enable verbose output
# end of vars that must be duplicated in the do_in_docker function

THIS_VERSION="0.0.1"                                 # version of this script
export DOCKER_CLI_HINTS="${DOCKER_CLI_HINTS:-false}" # disable ads from the Docker CLI 🖕💩

# utility functions

# mimic the help output from clap-rs
show_help() {
  cat <<EOF
Build script for Docker images

$(tput bold)$(tput smul)Usage:$(tput sgr0) $(tput bold)$0$(tput sgr0) [OPTIONS] [CONTEXT]

$(tput bold)$(tput smul)Context:$(tput sgr0)
  Any number of Docker build contexts
  If not provided, all directories containing a Dockerfile will be used

  $(tput bold)$(tput smul)Detected contexts:$(tput sgr0)
    $(tput bold)$(find_contexts | sed 's|^\./||' | paste -s - | sed 's/\t/\, /g')$(tput sgr0)

$(tput bold)$(tput smul)Options:$(tput sgr0)
  $(tput bold)-h,     --help$(tput sgr0)    Show this help message
  $(tput bold)-V,     --version$(tput sgr0) Show the version of this script
  $(tput bold)-v,     --verbose$(tput sgr0) Enable verbose output
  $(tput bold)--test, --ttl$(tput sgr0)     Push to the ttl.sh registry
  $(tput bold)-b,     --build$(tput sgr0)   Build the docker images
  $(tput bold)-p,     --push$(tput sgr0)    Push the docker images
  $(tput bold)-u,     --update$(tput sgr0)  Pull the latest version number for the upstream project

$(tput bold)$(tput smul)Env:$(tput sgr0)
  $(tput bold)BUILD_PLATFORMS$(tput sgr0): $(tput setaf 016)$BUILD_PLATFORMS$(tput sgr0)
  $(tput bold)CURL_ARGS$(tput sgr0): (ex: --header "Authorization Bearer ****")
  $(tput bold)CONTAINER_BUILD_CONTEXTS$(tput sgr0): (ex: ./curl, ./nano, etc.)
  $(tput bold)CONTAINER_REGISTRY$(tput sgr0): $(tput setaf 016)$CONTAINER_REGISTRY$(tput sgr0)
  $(tput bold)CONTAINER_REPO$(tput sgr0): $(tput setaf 016)$CONTAINER_REPO$(tput sgr0)
  $(tput bold)CONTAINER_ENGINE_SOCKET$(tput sgr0): $(tput setaf 016)$CONTAINER_ENGINE_SOCKET$(tput sgr0)
  $(tput bold)DOINDOCKER$(tput sgr0): $(tput setaf 016)$DOINDOCKER$(tput sgr0)
  $(tput bold)DOINDOCKER_BUILD_TOOLS$(tput sgr0): $(tput setaf 016)$DOINDOCKER_BUILD_TOOLS$(tput sgr0)
  $(tput bold)REGISTRY_USER$(tput sgr0): $(tput setaf 016)$REGISTRY_USER$(tput sgr0)
  $(tput bold)REGISTRY_PAT$(tput sgr0): (ex: dckr_pat_****)
  $(tput bold)ATTESTATION_ARGS$(tput sgr0): $(tput setaf 016)$ATTESTATION_ARGS$(tput sgr0)
  $(tput bold)VERBOSE$(tput sgr0): $(tput setaf 016)$VERBOSE$(tput sgr0)
EOF
}

# used to create a clickable link to the line in this script in log output
line_output() {
  echo "$0: line $1"
}

if [[ -n "${NO_COLOR:-}" ]]; then
  tput() { :; }
fi

# enable psuedo breakpoints in debug mode
if [[ "$BREAKPOINT" == "1" ]]; then
  # FIXME: TTY requires pressing Enter twice to continue when a function before it redirected stderr...
  log() {
    tput bel
    printf "$(tput setaf 6)❕ %-20s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1"
    read -r -p "   ↳ $(tput setaf 5)$2:$(tput sgr0) Press Enter to continue." ||
      { log "entering shell" "$(line_output $LINENO)" && /usr/bin/env bash -i; }
  } >&2
  err() {
    tput bel
    printf "$(tput setaf 1)❌ %-20s$(tput sgr0)\t\t%s\n\n" "${context:-main}" "$1"
    read -r -p "   ↳ $(tput setaf 1)$2:$(tput sgr0) Breakpoint. Press Enter to enter an interactive environment, or press Ctrl+C to continue." ||
      { log "entering shell" "$(line_output $LINENO)" && /usr/bin/env bash -i; }
  } >&2
  log "Breakpoints enabled" "$(line_output $LINENO)"
else
  log() {
    printf "$(tput setaf 6)❕ %-20s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1" >&2
  }
  err() {
    printf "$(tput setaf 1)❌ %-20s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1" >&2
    exit 1
  }
fi

# run the builds in a docker container
# useful to ensure the build environment is consistent
do_in_docker() {
  log "Running in docker" "$(line_output $LINENO)"

  container_id=$(
    docker run --rm -d $IS_TTY \
      -v "$CONTAINER_ENGINE_SOCKET":/var/run/docker.sock \
      -v "$REPO_ROOT:/$REPO_ROOT" \
      -w /"$REPO_ROOT" \
      -e BASENAME="$BASENAME" \
      -e BREAKPOINT="$BREAKPOINT" \
      -e BUILD_PLATFORMS="$BUILD_PLATFORMS" \
      -e CONTAINER_ENGINE_SOCKET=/var/run/docker.sock \
      -e CONTAINER_BUILD_CONTEXTS="$CONTAINER_BUILD_CONTEXTS" \
      -e CONTAINER_REGISTRY="$CONTAINER_REGISTRY" \
      -e CONTAINER_REPO="$CONTAINER_REPO" \
      -e DOINDOCKER='#already in docker' \
      -e DOINDOCKER_BUILD_TOOLS="$DOINDOCKER_BUILD_TOOLS" \
      -e GH_TOKEN="$(gh auth token || echo -n)" \
      -e NO_COLOR="$NO_COLOR" \
      -e REGISTRY_USER="$REGISTRY_USER" \
      -e REGISTRY_PAT="$REGISTRY_PAT" \
      -e REPO_ROOT="$REPO_ROOT" \
      -e ATTESTATION_ARGS="$ATTESTATION_ARGS" \
      -e VERBOSE="$VERBOSE" \
      --stop-signal SIGKILL \
      docker:latest \
      tail -f /dev/null
  )

  docker exec $IS_TTY "$container_id" /bin/sh -c "
    apk add --no-cache $DOINDOCKER_BUILD_TOOLS || { echo failed && exit 1; }
    git config --global --add safe.directory $REPO_ROOT || { echo failed && exit 1; }
    exec ./build-images.sh $* || { echo failed && exit 1; }
  " || err "Failed to run in docker" "$(line_output $LINENO)"
}

# get the latest tag from a git repo
# add special cases for returning the latest tag as needed
git_latest_tag() {
  local url="$1"

  case $url in
  *curl*)
    # curl releases are tagged with a prefix of "curl-";
    # we need to grab the latest tag that starts with "curl-"
    log "curl" "$(line_output $LINENO)"
    git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{print $3}' |
      sort -r |
      grep -m 1 -e '^curl-'
    ;;
  *)
    git ls-remote --tags --refs --sort="v:refname" "$url" | tail -n1 | awk -F/ '{print $3}'
    ;;
  esac

}

# attempt to fetch the latest version from a URL
fetch_latest_version() {
  log "fetch_latest_version $1" "$(line_output $LINENO)"
  local url="$1"
  if [[ -z "$url" ]]; then
    log "No URL provided" "$(line_output $LINENO)"
    echo "NOVER"
    return 0
  fi

  # shellcheck disable=SC2086,SC2064
  # works well for GitHub-hosted code
  curl -sL \
    $CURL_ARGS \
    "$url" | jq -r '.tag_name' 2>/dev/null ||
    # hopefully works for other git repos
    { git_latest_tag "$url" 2>/dev/null; } ||
    { err "could not get latest version." "$(line_output $LINENO)"; }
}

# retrieve the latest version of an upstream project
# and store it in a .version file in the context directory
get_latest_upstream_version() {
  for context in $CONTAINER_BUILD_CONTEXTS; do
    local url="$(cat "$context"/.url 2>/dev/null || true)"
    local ver="$(fetch_latest_version "$url")"
    if [[ "$ver" == "NOVER" ]]; then
      log "No VERSION could be derived from $context/.url" "$(line_output $LINENO)"
      echo "latest" >"$context/.version"
      continue
    fi

    log "Latest version of '$context' is '$ver'" "$(line_output $LINENO)"
    echo "$ver" >"$context/.version"
  done
}

# this function will take a variety of version strings, such as any one of the following:
#   ${NULL}, 1.2.3, v1.2.3, or curl-1_2_3
# and normalizes them into docker tags, such as:
#   1.2.3, v1.2.3, curl-1_2_3, latest
# if we recieve an "odd" version string, like curl-1_2_3,
# we'll just use that as the tag, along with latest, and the other normalizations
# if we recieve ${NULL}, skip the normalization and just return "latest"
create_version_aliases() {
  local version="$1"
  local tag_default="$1" # retain the original version string
  local tag_no_v_prefix
  local tag_v_prefix

  # exit early if using the default 'latest' version
  if [[ "$version" == "latest" ]]; then
    echo "latest"
    return
  fi

  # normalize the version string
  if [[ ! "$version" =~ ^[0-9] ]]; then
    # replace non-numeric characters with '.'
    version="${version//[^0-9]/.}"
    # remove any leading or trailing dots
    version="$(echo "$version" | sed -e 's/^\.*//' -e 's/\.*$//')"
  fi

  tag_no_v_prefix="$version"
  tag_v_prefix="v$version"

  {
    # return the tags in a normalized order, with 'latest' at the end
    echo "$version"
    echo "$tag_default"
    echo "$tag_no_v_prefix"
    echo "$tag_v_prefix"
    echo "latest"
  } | sort -u |
    awk '{if ($0 == "latest") {latest=$0} else {print $0}} END {if (latest) print latest}' |
    tr '\n' ' '
}

build_oci_uri() {
  local image_name="$1"
  if [[ "$CONTAINER_REGISTRY" == "ttl.sh" ]]; then
    log "Using ttl.sh registry" "$(line_output $LINENO)"
    local version="latest"
  else
    local tags="$2"
  fi

  {
    # check each component of the URI
    log "Building docker URI" "$(line_output $LINENO)"
    log "CONTAINER_REGISTRY: $CONTAINER_REGISTRY" "$(line_output $LINENO)"
    [[ -n "$CONTAINER_REGISTRY" ]] && echo -n "$CONTAINER_REGISTRY/"
    log "CONTAINER_REPO: $CONTAINER_REPO" "$(line_output $LINENO)"
    [[ -n "$CONTAINER_REPO" ]] && echo -n "$CONTAINER_REPO/"
    log "image_name: $image_name" "$(line_output $LINENO)"
    [[ -n "$image_name" ]] && echo -n "$image_name:"
    log "version: $version" "$(line_output $LINENO)"
    [[ -n "$version" ]] && echo -n "$version"
  } | tr -d '\n' | sed 's/ $//'
}

build_docker() {
  local context="$1"
  local version

  log "Building docker images" "$(line_output $LINENO)"
  log "CONTAINER_BUILD_CONTEXTS: $CONTAINER_BUILD_CONTEXTS" "$(line_output $LINENO)"
  for context in $CONTAINER_BUILD_CONTEXTS; do
    version="$(cat "$context/.version" || echo latest)"
    tags="$(create_version_aliases "$version")"

    log "context: $context" "$(line_output $LINENO)"
    log "tags: $tags" "$(line_output $LINENO)"
    log "version: $version" "$(line_output $LINENO)"

    local oci_uri="$(build_oci_uri "$context" "$tags")"
    log "Building $oci_uri" "$(line_output $LINENO)"
    [[ -f "$context"/.nobuild ]] && log ".nobuild file found. Skipping $context" "$(line_output $LINENO)" && continue

    # shellcheck disable=SC2086
    docker build \
      --platform "$BUILD_PLATFORMS" \
      --build-arg VERSION="$version" \
      $ATTESTATION_ARGS \
      -t "$oci_uri" \
      "$context" || { log "Failed to build $oci_uri. Continuing..." "$(line_output $LINENO)" >/dev/stderr; }

    for tag in $tags; do
      new_tag="${oci_uri%:*}:$tag"
      log "Tagging $oci_uri as $new_tag" "$(line_output $LINENO)"
      docker tag "$oci_uri" "$new_tag" || { log "Failed to tag $new_tag. Continuing..." "$(line_output $LINENO)" >/dev/stderr; }
    done
  done
}

# push the container images to the registry
push_docker() {
  local context="$1"
  local version

  if [[ "$CONTAINER_REGISTRY" != "ttl.sh" ]]; then
    log "Logging in to $CONTAINER_REGISTRY" "$(line_output $LINENO)"
    echo "$REGISTRY_PAT" |
      docker login "$CONTAINER_REGISTRY" \
        --username "${REGISTRY_USER:-CONTAINER_REPO}" \
        --password-stdin ||
      { err "Failed to login to $CONTAINER_REGISTRY" "$(line_output $LINENO)" >/dev/stderr; }
  fi

  log "Pushing docker images" "$(line_output $LINENO)"
  log "CONTAINER_BUILD_CONTEXTS: $CONTAINER_BUILD_CONTEXTS" "$(line_output $LINENO)"
  for context in $CONTAINER_BUILD_CONTEXTS; do
    # if "$context"/.nopush exists, skip pushing this image
    [[ -f "$context"/.nopush ]] && log ".nopush file found. Skipping $context" "$(line_output $LINENO)" && continue
    version="$(cat "$context/.version" || echo latest)"
    tags="$(create_version_aliases "$version")"

    log "context: $context" "$(line_output $LINENO)"
    log "tags: $tags" "$(line_output $LINENO)"
    log "version: $version" "$(line_output $LINENO)"

    local oci_uri="$(build_oci_uri "$context" "$tags")"
    log "Pushing $oci_uri" "$(line_output $LINENO)"
    # shellcheck disable=SC2086
    docker push "$oci_uri" || { log "Failed to push $oci_uri. Continuing..." "$(line_output $LINENO)" >/dev/stderr; }

    for tag in $tags; do
      new_tag="${oci_uri%:*}:$tag"
      log "Pushing $new_tag" "$(line_output $LINENO)"
      # shellcheck disable=SC2086
      docker push "$new_tag" || { log "Failed to push $new_tag. Continuing..." "$(line_output $LINENO)" >/dev/stderr; }
    done
  done
}

main() {
  pushd "$REPO_ROOT" >/dev/null || exit 1
  trap 'popd >/dev/null' EXIT

  UPDATE=0
  BUILD=0
  PUSH=0

  while [[ $# -gt 0 ]]; do
    case $1 in
    -v | --verbose)
      VERBOSE=1
      shift 1
      ;;
    --test | --ttl)
      # push to ttl.sh registry; good for testing
      CONTAINER_REGISTRY="ttl.sh"
      CONTAINER_REPO=""
      PUSH=1
      shift 1
      ;;
    -u | --update)
      UPDATE=1
      shift 1
      ;;
    -b | --build)
      BUILD=1
      shift 1
      ;;
    -p | --push)
      PUSH=1
      shift 1
      ;;
    *)
      CONTAINER_BUILD_CONTEXTS="$*"
      break
      ;;
    esac
  done

  if [[ "$UPDATE" == "0" && "$BUILD" == "0" && "$PUSH" == "0" ]]; then
    BUILD=1
    PUSH=1
  fi

  if [[ -z "$CONTAINER_BUILD_CONTEXTS" ]]; then
    CONTAINER_BUILD_CONTEXTS="$(find_contexts)"
  fi

  if [[ "$UPDATE" == "1" ]]; then
    get_latest_upstream_version
  fi

  if [[ "$BUILD" == "1" ]]; then
    build_docker "$@"
  fi

  if [[ "$PUSH" == "1" ]]; then
    push_docker "$@"
  fi
}

# Put any commands here that should subvert running in Docker and using the trap
for arg in "$@"; do
  case $arg in
  -h | --help)
    show_help
    exit 0
    ;;
  -V | --version)
    echo "$THIS_VERSION"
    exit 0
    ;;
  esac
done

if ! command -v docker &>/dev/null; then
  err "Docker is not installed" "$(line_output $LINENO)"
fi

trap '
  log "Exiting: Cleaning up Docker container $container_id" "$(line_output $LINENO)"; \
  docker rm -f "$container_id" >/dev/null || \
    err "Failed to remove container" "$(line_output $LINENO)"; \
  log "Last command: $BASH_COMMAND" "$(line_output $LINENO)"; \
  log "Stack trace:" "$(line_output $LINENO)"; \
  log "$(caller)" "$(line_output $LINENO)"
' EXIT

if [[ "$VERBOSE" == "1" ]]; then
  set -x
fi

if [[ -t 1 ]]; then
  IS_TTY="-it"
else
  IS_TTY=""
fi

if [[ "$DOINDOCKER" == "1" ]]; then
  do_in_docker "$@"
else
  main "$@"
fi
