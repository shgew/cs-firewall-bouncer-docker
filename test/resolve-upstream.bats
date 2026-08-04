bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit 1
}

@test "bootstrap: stable=v0.0.34, rc=v0.0.35-rc3" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-bootstrap.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.stable.version == "v0.0.34"'
  echo "$output" | jq -e '.rc.version == "v0.0.35-rc3"'
}

@test "stable-overtakes: v0.0.35 stable makes both channels v0.0.35" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-stable-overtakes.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.stable.version == "v0.0.35"'
  echo "$output" | jq -e '.rc.version == "v0.0.35"'
}

@test "new-rc-after-stable: rc=v0.0.36-rc1, stable=v0.0.35" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-new-rc.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.rc.version == "v0.0.36-rc1"'
  echo "$output" | jq -e '.stable.version == "v0.0.35"'
}

@test "rc-numeric-ordering: rc10 beats rc2" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-rc-ordering.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.rc.version == "v0.0.35-rc10"'
}

@test "no-downgrade: keeps current when only older releases present" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-older-only.json test/fixtures/versions-old.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.stable.version == "v0.0.34"'
  [[ "$stderr" == *"warning"* ]]
}

@test "exclusions: draft and non-matching tags ignored" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-with-excluded.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.stable.version == "v0.0.34"'
}

@test "prerelease flag ignored: a bare tag flagged prerelease becomes the stable head" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-prerelease-flagged-stable.json test/fixtures/versions-current.json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.stable.version == "v0.0.36"'
  echo "$output" | jq -e '.rc.version == "v0.0.36"'
  echo "$output" | jq -e '.stable.tarballs.amd64 == "sha256:f86e4b72693549d99f40a9402abefb894108f047a3fbe6e72fada25ee17ce88b"'
}

@test "missing arm64 asset exits 1 with asset name in message" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-missing-arm64.json test/fixtures/versions-current.json
  [ "$status" -ne 0 ]
  [[ "$output" == *"arm64"* ]] || [[ "$stderr" == *"arm64"* ]]
}

@test "shuffled fixture order produces identical output" {
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-bootstrap.json test/fixtures/versions-current.json
  out_normal="$output"
  run --separate-stderr scripts/resolve-upstream.sh test/fixtures/releases-shuffled.json test/fixtures/versions-current.json
  [ "$output" = "$out_normal" ]
}
