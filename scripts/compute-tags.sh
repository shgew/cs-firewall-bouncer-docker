#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <git-tag> <prerelease: true|false> <versions-json-file> <image-base>" >&2
  echo "  git-tag must match ^v[0-9]+.[0-9]+.[0-9]+(-rcN)?(+patchN)?\$" >&2
}

if [ "$#" -ne 4 ]; then
  usage
  exit 1
fi

git_tag="$1"
prerelease="$2"
versions_file="$3"
image_base="$4"

tag_re='^v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(\+patch[0-9]+)?$'
if [[ ! "$git_tag" =~ $tag_re ]]; then
  usage
  exit 1
fi

docker_version_tag="${git_tag//+/-}"

if [ "$prerelease" = "true" ]; then
  channel="rc"
else
  channel="stable"
fi

base="${git_tag%%+*}"

head="$(jq -r --arg ch "$channel" '.[$ch].version // ""' "$versions_file")"
if [ "$base" != "$head" ]; then
  echo "versions.json $channel head is $head, release is $base: update versions.json first" >&2
  exit 1
fi

echo "${image_base}:${docker_version_tag}"

if [ "$channel" = "stable" ]; then
  echo "${image_base}:stable"
  echo "${image_base}:latest"
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
    echo "${image_base}:rc"
  fi
else
  echo "${image_base}:rc"
fi
