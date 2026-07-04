#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s <releases-json-file> <current-versions-json-file>\n' "${0##*/}" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

releases_file="$1"
current_file="$2"

if [ ! -f "$releases_file" ]; then
  printf 'error: releases file not found: %s\n' "$releases_file" >&2
  exit 1
fi

if [ ! -f "$current_file" ]; then
  printf 'error: current versions file not found: %s\n' "$current_file" >&2
  exit 1
fi

read -r -d '' jq_program <<'JQ' || true
def parsekey:
  (capture("^v(?<maj>[0-9]+)\\.(?<min>[0-9]+)\\.(?<pat>[0-9]+)(-rc(?<rc>[0-9]+))?$")) as $m
  | [ ($m.maj | tonumber),
      ($m.min | tonumber),
      ($m.pat | tonumber),
      (if $m.rc == null then 1 else 0 end),
      (if $m.rc == null then 0 else ($m.rc | tonumber) end) ];

def digestof($rel; $name):
  ($rel.assets // [] | map(select(.name == $name)) | (.[0].digest // ""));

def channel_entry($rel):
  ($rel.tag_name) as $ver
  | digestof($rel; "crowdsec-firewall-bouncer-linux-amd64.tgz") as $amd
  | digestof($rel; "crowdsec-firewall-bouncer-linux-arm64.tgz") as $arm
  | (if ($amd | length) == 0
       then error("missing asset crowdsec-firewall-bouncer-linux-amd64.tgz in release " + $ver)
     elif ($arm | length) == 0
       then error("missing asset crowdsec-firewall-bouncer-linux-arm64.tgz in release " + $ver)
     else {version: $ver, tarballs: {amd64: $amd, arm64: $arm}}
     end);

($releases[0]
 | map(select(.draft == false
              and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+(-rc[0-9]+)?$"))))) as $cands
| ($cands
   | map(select(.prerelease == false
                and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))))
   | sort_by(.tag_name | parsekey)
   | last) as $stable_head
| ($cands | sort_by(.tag_name | parsekey) | last) as $rc_head
| $current[0] as $cur
| (if $stable_head == null
     then {entry: $cur.stable, warn: null}
   elif ($stable_head.tag_name | parsekey) < ($cur.stable.version | parsekey)
     then {entry: $cur.stable,
           warn: ("warning: stable channel computed head " + $stable_head.tag_name
                  + " is lower than current " + $cur.stable.version + "; keeping current")}
   else {entry: channel_entry($stable_head), warn: null}
   end) as $stable_res
| (if $rc_head == null
     then {entry: $cur.rc, warn: null}
   elif ($rc_head.tag_name | parsekey) < ($cur.rc.version | parsekey)
     then {entry: $cur.rc,
           warn: ("warning: rc channel computed head " + $rc_head.tag_name
                  + " is lower than current " + $cur.rc.version + "; keeping current")}
   else {entry: channel_entry($rc_head), warn: null}
   end) as $rc_res
| {result: {stable: $stable_res.entry, rc: $rc_res.entry},
   warnings: ([$stable_res.warn, $rc_res.warn] | map(select(. != null)))}
JQ

combined="$(jq -n \
  --slurpfile releases "$releases_file" \
  --slurpfile current "$current_file" \
  "$jq_program")"

warnings="$(printf '%s' "$combined" | jq -r '.warnings[]')"
if [ -n "$warnings" ]; then
  printf '%s\n' "$warnings" >&2
fi

printf '%s' "$combined" | jq '.result'
