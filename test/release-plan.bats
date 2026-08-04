bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit 1
}

@test "bare stable tag: stable channel, stable and latest aliases, no rc alias" {
  run scripts/release-plan.sh v0.0.34 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.channel == "stable"'
  echo "$output" | jq -e '.version == "v0.0.34"'
  echo "$output" | jq -e '.image_tags == ["ghcr.io/x:v0.0.34", "ghcr.io/x:stable", "ghcr.io/x:latest"]'
}

@test "rc tag: rc channel from tag shape, rc alias only" {
  run scripts/release-plan.sh v0.0.35-rc3 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.channel == "rc"'
  echo "$output" | jq -e '.image_tags == ["ghcr.io/x:v0.0.35-rc3", "ghcr.io/x:rc"]'
}

@test "stable caught up with rc: adds rc alias" {
  run scripts/release-plan.sh v0.0.35 test/fixtures/versions-catchup.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.image_tags == ["ghcr.io/x:v0.0.35", "ghcr.io/x:stable", "ghcr.io/x:latest", "ghcr.io/x:rc"]'
}

@test "docker_tag replaces + with - and stays non-empty" {
  run scripts/release-plan.sh v0.0.34+patch2 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.docker_tag == "v0.0.34-patch2"'
  echo "$output" | jq -e '.image_tags[0] == "ghcr.io/x:v0.0.34-patch2"'
}

@test "patch tag keeps the upstream version as the build arg" {
  run scripts/release-plan.sh v0.0.34+patch2 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.version == "v0.0.34"'
  echo "$output" | jq -e '.channel == "stable"'
}

@test "rc patch tag resolves the rc channel" {
  run scripts/release-plan.sh v0.0.35-rc3+patch1 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.channel == "rc"'
  echo "$output" | jq -e '.docker_tag == "v0.0.35-rc3-patch1"'
  echo "$output" | jq -e '.version == "v0.0.35-rc3"'
}

@test "checksums come from the resolved channel" {
  run scripts/release-plan.sh v0.0.35-rc3 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.tarballs.amd64 == "sha256:37aa7b0c767861ade7fd054d93165ce2dbaabd2eaf9b41a59231931d63a0b00b"'
  echo "$output" | jq -e '.tarballs.arm64 == "sha256:007d7bd9defc62b94ab3c9ba3e483cf4599aed0dd223887a0256bbd3fa3600e7"'
}

@test "non-head version exits 1 with update-versions.json message" {
  run --separate-stderr scripts/release-plan.sh v0.0.33+patch9 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"update versions.json first"* ]]
}

@test "unknown version exits 1" {
  run scripts/release-plan.sh v0.0.99 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 1 ]
}

@test "bad grammar v1.2 exits 1" {
  run scripts/release-plan.sh v1.2 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 1 ]
}

@test "bad grammar v1.2.3-beta1 exits 1" {
  run scripts/release-plan.sh v1.2.3-beta1 test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 1 ]
}

@test "wrong argument count exits 2" {
  run scripts/release-plan.sh v0.0.34 test/fixtures/versions-stable-behind-rc.json
  [ "$status" -eq 2 ]
}
