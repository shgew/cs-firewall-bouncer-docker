#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s <mirror|patch> <stable|rc> <versions-json-file> <existing-tags-file|->\n' "${0##*/}" >&2
  printf '  mirror: bare upstream version, refused if that version is already tagged\n' >&2
  printf '  patch:  next +patchN, refused unless that version was already released here\n' >&2
}

if [ "$#" -ne 4 ]; then
  usage
  exit 2
fi

mode="$1"
channel="$2"
versions_file="$3"
tags_source="$4"

case "$mode" in
  mirror | patch) ;;
  *)
    usage
    exit 2
    ;;
esac

case "$channel" in
  stable | rc) ;;
  *)
    usage
    exit 2
    ;;
esac

if [ ! -f "$versions_file" ]; then
  printf 'error: versions file not found: %s\n' "$versions_file" >&2
  exit 1
fi

version="$(jq -r --arg ch "$channel" '.[$ch].version // ""' "$versions_file")"
if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$ ]]; then
  printf 'error: versions.json %s head is not an upstream version: %s\n' \
    "$channel" "${version:-<missing>}" >&2
  exit 1
fi

if [ "$tags_source" = "-" ]; then
  tags="$(cat)"
elif [ -f "$tags_source" ]; then
  tags="$(cat "$tags_source")"
else
  printf 'error: tags file not found: %s\n' "$tags_source" >&2
  exit 1
fi

mirror_tagged=false
highest_patch=0
while IFS= read -r tag; do
  tag="${tag%$'\r'}"
  if [ "$tag" = "$version" ]; then
    mirror_tagged=true
    continue
  fi
  suffix="${tag#"$version"+patch}"
  if [ "$suffix" = "$tag" ] || [[ ! "$suffix" =~ ^[0-9]+$ ]]; then
    continue
  fi
  patch_number="$((10#$suffix))"
  if [ "$patch_number" -gt "$highest_patch" ]; then
    highest_patch="$patch_number"
  fi
done <<<"$tags"

if [ "$mode" = "mirror" ]; then
  if [ "$mirror_tagged" = true ]; then
    printf 'error: %s is already tagged; an upstream version is mirrored exactly once\n' "$version" >&2
    exit 1
  fi
  printf '%s\n' "$version"
  exit 0
fi

if [ "$mirror_tagged" != true ] && [ "$highest_patch" -eq 0 ]; then
  printf 'error: this repository has never released %s; mirror it as %s before patching\n' \
    "$version" "$version" >&2
  exit 1
fi

printf '%s+patch%d\n' "$version" "$((highest_patch + 1))"
