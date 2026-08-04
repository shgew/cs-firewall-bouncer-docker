#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s <git-tag> <versions-json-file> <image-base>\n' "${0##*/}" >&2
  printf '  git-tag must match ^v[0-9]+.[0-9]+.[0-9]+(-rcN)?(+patchN)?$\n' >&2
}

if [ "$#" -ne 3 ]; then
  usage
  exit 2
fi

git_tag="$1"
versions_file="$2"
image_base="$3"

if [[ ! "$git_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(\+patch[0-9]+)?$ ]]; then
  usage
  exit 1
fi

if [ ! -f "$versions_file" ]; then
  printf 'error: versions file not found: %s\n' "$versions_file" >&2
  exit 1
fi

version="${git_tag%%+*}"
docker_tag="${git_tag//+/-}"

case "$version" in
  *-rc*) channel=rc ;;
  *) channel=stable ;;
esac

head="$(jq -r --arg ch "$channel" '.[$ch].version // ""' "$versions_file")"
if [ "$version" != "$head" ]; then
  printf 'versions.json %s head is %s, release is %s: update versions.json first\n' \
    "$channel" "${head:-<missing>}" "$version" >&2
  exit 1
fi

sha_amd64="$(jq -r --arg ch "$channel" '.[$ch].tarballs.amd64 // ""' "$versions_file")"
sha_arm64="$(jq -r --arg ch "$channel" '.[$ch].tarballs.arm64 // ""' "$versions_file")"
if [ -z "$sha_amd64" ] || [ -z "$sha_arm64" ]; then
  printf 'versions.json %s channel is missing per-arch tarball checksums\n' "$channel" >&2
  exit 1
fi

image_tags=("${image_base}:${docker_tag}")
if [ "$channel" = "stable" ]; then
  image_tags+=("${image_base}:stable" "${image_base}:latest")
  if jq -e '
      def parse:
        capture("^v(?<maj>[0-9]+)\\.(?<min>[0-9]+)\\.(?<pat>[0-9]+)(-rc(?<rc>[0-9]+))?$")
        | [
            (.maj | tonumber),
            (.min | tonumber),
            (.pat | tonumber),
            (if .rc then 0 else 1 end),
            (if .rc then (.rc | tonumber) else 0 end)
          ];
      (.stable.version | parse) >= (.rc.version | parse)
    ' "$versions_file" >/dev/null; then
    image_tags+=("${image_base}:rc")
  fi
else
  image_tags+=("${image_base}:rc")
fi

jq -n \
  --arg channel "$channel" \
  --arg version "$version" \
  --arg docker_tag "$docker_tag" \
  --arg amd64 "$sha_amd64" \
  --arg arm64 "$sha_arm64" \
  '{
    channel: $channel,
    version: $version,
    docker_tag: $docker_tag,
    tarballs: {amd64: $amd64, arm64: $arm64},
    image_tags: $ARGS.positional
  }' \
  --args "${image_tags[@]}"
