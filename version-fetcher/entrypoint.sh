#!/usr/bin/env bash
# shellcheck disable=SC2155
set -eo pipefail

# env setup
find_contexts() {
  # find all directories containing a Dockerfile
  find /build_contexts -type f -name Dockerfile -exec dirname {} \; | sort | sed 's|^\./||'
  cd /build_contexts
}

CONTAINER_BUILD_CONTEXTS="${CONTAINER_BUILD_CONTEXTS:-$(find_contexts)}" # directories containing Dockerfiles
THIS_VERSION="0.0.1"                                                     # version of this script
VERBOSE="${VERBOSE:-0}"                                                  # set to '1' to enable verbose output

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
  $(tput bold)-u,     --update$(tput sgr0)  Pull the latest version number for the upstream project

$(tput bold)$(tput smul)Env:$(tput sgr0)
  $(tput bold)CONTAINER_BUILD_CONTEXTS$(tput sgr0): (ex: ./curl, ./nano, etc.)
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
    printf "$(tput setaf 6)❕ %-30s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1"
    read -r -p "   ↳ $(tput setaf 5)$2:$(tput sgr0) Press Enter to continue." ||
      { log "entering shell" "$(line_output $LINENO)" && /usr/bin/env bash -i; }
  } >&2
  err() {
    tput bel
    printf "$(tput setaf 1)❌ %-30s$(tput sgr0)\t\t%s\n\n" "${context:-main}" "$1"
    read -r -p "   ↳ $(tput setaf 1)$2:$(tput sgr0) Breakpoint. Press Enter to enter an interactive environment, or press Ctrl+C to continue." ||
      { log "entering shell" "$(line_output $LINENO)" && /usr/bin/env bash -i; }
  } >&2
  log "Breakpoints enabled" "$(line_output $LINENO)"
else
  log() {
    printf "$(tput setaf 6)❕ %-30s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1" >&2
  }
  err() {
    printf "$(tput setaf 1)❌ %-30s$(tput sgr0)\t\t%s\n" "${context:-main}" "$1" >&2
    exit 1
  }
fi

# get the latest tag from a git repo
# add special cases for returning the latest tag as needed
git_latest_tag() {
  log "git_latest_tag" "$(line_output $LINENO)"
  local url="$1"
  local project_alias="$2"

  case $project_alias in
  *curl*)
    log "curl" "$(line_output $LINENO)"
    git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{ print $3 }' |
      sort -r -V |
      grep -m 1 -e '^curl-'
    ;;
  *helix*)
    # helix tags are simply versions (24.07)
    log "helix" "$(line_output $LINENO)"
    git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{ print $3 }' |
      sort -r | grep -m1 -E '^[0-9]{2}\.[0-9]{2}'
    ;;
  *nano*)
    log "nano" "$(line_output $LINENO)"
    git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{ print $3 }' |
      sort -r -V | head -n1
    ;;
  *)
    git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{ print $3 }' |
      sort -r -V |
      grep -m 1 -e "^$project_alias-" ||
      git ls-remote --tags --refs --sort="v:refname" "$url" |
      awk -F/ '{ print $3 }' |
        sort -r -V | head -n1
    ;;
  esac

}

# attempt to fetch the latest version from a URL
fetch_latest_version() {
  log "fetch_latest_version from '$1' with project name '$2'" "$(line_output $LINENO)"
  local url="$1"
  local project_alias="$2"

  if [[ -z "$url" ]]; then
    log "No URL provided" "$(line_output $LINENO)"
    echo "NOVER"
    return 0
  fi

  # hopefully works for most git repos
  { git_latest_tag "$url" "$project_alias" 2>/dev/null; } ||
    {
      # shellcheck disable=SC2086,SC2064
      curl -sL $CURL_ARGS "$url" | jq -r '.tag_name' 2>/dev/null
    } ||
    { err "could not get latest version." "$(line_output $LINENO)"; }
}

# retrieve the latest version of an upstream project
# and store it in a .version file in the context directory
get_latest_upstream_version() {
  for context in $CONTAINER_BUILD_CONTEXTS; do
    local url="$(awk '{ print $1 }' "$context/.url" 2>/dev/null || true)"
    local project_alias="$(awk '{ print $3 }' "$context"/.url 2>/dev/null || true)"
    local current_ver="$(cat "$context"/.version 2>/dev/null || true)"
    local ver="$(fetch_latest_version "$url" "$project_alias")"

    if [[ "$current_ver" = "$ver" ]]; then
      log "Update not needed" "$(line_output $LINENO)"
      continue
    fi

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

main() {
  cd /build_contexts >/dev/null || exit 1
  trap 'cd / >/dev/null' EXIT

  UPDATE=0

  while [ $# -gt 0 ]; do
    case $1 in
    -v | --verbose)
      VERBOSE=1
      shift 1
      ;;
    -u | --update)
      UPDATE=1
      shift 1
      ;;
    *)
      CONTAINER_BUILD_CONTEXTS="$*"
      break
      ;;
    esac
  done

  if [[ -z "$CONTAINER_BUILD_CONTEXTS" ]]; then
    CONTAINER_BUILD_CONTEXTS="$(find_contexts)"
  fi

  if [[ "$UPDATE" == "1" ]]; then
    get_latest_upstream_version
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

trap '
  log "Last command: $BASH_COMMAND" "$(line_output $LINENO)"; \
  log "Stack trace:" "$(line_output $LINENO)"; \
  log "$(caller)" "$(line_output $LINENO)"
' EXIT

if [[ "$VERBOSE" == "1" ]]; then
  set -x
fi

main "$@"
