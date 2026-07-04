#!/usr/bin/env bats

@test "stable behind rc: no rc alias" {
  run scripts/compute-tags.sh v0.0.34 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  [[ "$output" == *"ghcr.io/x:v0.0.34"* ]]
  [[ "$output" == *"ghcr.io/x:stable"* ]]
  [[ "$output" == *"ghcr.io/x:latest"* ]]
  [[ "$output" != *"ghcr.io/x:rc"* ]]
}

@test "rc release: emits rc alias only" {
  run scripts/compute-tags.sh v0.0.35-rc3 true test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  [[ "$output" == *"ghcr.io/x:v0.0.35-rc3"* ]]
  [[ "$output" == *"ghcr.io/x:rc"* ]]
  [[ "$output" != *"ghcr.io/x:stable"* ]]
  [[ "$output" != *"ghcr.io/x:latest"* ]]
}

@test "catch-up: stable equals rc, adds rc alias" {
  run scripts/compute-tags.sh v0.0.35 false test/fixtures/versions-catchup.json ghcr.io/x
  [ "$status" -eq 0 ]
  [[ "$output" == *"ghcr.io/x:v0.0.35"* ]]
  [[ "$output" == *"ghcr.io/x:stable"* ]]
  [[ "$output" == *"ghcr.io/x:latest"* ]]
  [[ "$output" == *"ghcr.io/x:rc"* ]]
}

@test "patch on stable head: emits patched version plus stable aliases" {
  run scripts/compute-tags.sh v0.0.34+patch1 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  [[ "$output" == *"ghcr.io/x:v0.0.34-patch1"* ]]
  [[ "$output" == *"ghcr.io/x:stable"* ]]
  [[ "$output" == *"ghcr.io/x:latest"* ]]
}

@test "patch on rc head: emits patched rc version and rc alias" {
  run scripts/compute-tags.sh v0.0.35-rc3+patch1 true test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -eq 0 ]
  [[ "$output" == *"ghcr.io/x:v0.0.35-rc3-patch1"* ]]
  [[ "$output" == *"ghcr.io/x:rc"* ]]
}

@test "patch on non-head: exits 1 with update-versions.json message" {
  run scripts/compute-tags.sh v0.0.33+patch9 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -ne 0 ]
  [[ "$output" == *"update versions.json first"* ]]
}

@test "unknown version exits 1" {
  run scripts/compute-tags.sh v0.0.99 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -ne 0 ]
}

@test "bad grammar v1.2 exits 1" {
  run scripts/compute-tags.sh v1.2 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -ne 0 ]
}

@test "bad grammar v1.2.3-beta1 exits 1" {
  run scripts/compute-tags.sh v1.2.3-beta1 false test/fixtures/versions-stable-behind-rc.json ghcr.io/x
  [ "$status" -ne 0 ]
}
