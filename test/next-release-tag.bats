bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit 1
}

@test "mirror: untagged channel head yields the bare upstream version" {
  run scripts/next-release-tag.sh mirror rc test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.35-rc3" ]
}

@test "mirror: never adds a patch suffix for a fresh upstream version" {
  run scripts/next-release-tag.sh mirror stable test/fixtures/versions-catchup.json test/fixtures/tags-existing.txt
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.35" ]
}

@test "mirror: refuses to re-cut an already tagged upstream version" {
  run --separate-stderr scripts/next-release-tag.sh mirror stable test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"mirrored exactly once"* ]]
}

@test "patch: increments past the highest existing patch" {
  run scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch3" ]
}

@test "patch: refuses a version this repository never released" {
  run --separate-stderr scripts/next-release-tag.sh patch stable test/fixtures/versions-catchup.json test/fixtures/tags-existing.txt
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"never released v0.0.35"* ]]
}

@test "patch: allows a version released only under a patch tag" {
  run scripts/next-release-tag.sh patch rc test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.35-rc3+patch2" ]
}

@test "patch: orders patch numbers numerically, not lexically" {
  run bash -c 'printf "v0.0.34\nv0.0.34+patch9\nv0.0.34+patch10\n" | scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json -'
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch11" ]
}

@test "patch: reads a leading-zero suffix as decimal, not octal" {
  run bash -c 'printf "v0.0.34\nv0.0.34+patch9\nv0.0.34+patch010\n" | scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json -'
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch11" ]
}

@test "patch: a leading-zero suffix outside octal range still counts" {
  run bash -c 'printf "v0.0.34\nv0.0.34+patch08\n" | scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json -'
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch9" ]
}

@test "patch: ignores patch tags belonging to a different version" {
  run bash -c 'printf "v0.0.34\nv0.0.34-rc1+patch5\nv0.0.340+patch7\n" | scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json -'
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch1" ]
}

@test "patch: ignores malformed patch suffixes" {
  run bash -c 'printf "v0.0.34\nv0.0.34+patchX\nv0.0.34+patch\n" | scripts/next-release-tag.sh patch stable test/fixtures/versions-stable-behind-rc.json -'
  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.34+patch1" ]
}

@test "rejects an unknown mode" {
  run scripts/next-release-tag.sh promote stable test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 2 ]
}

@test "rejects an unknown channel" {
  run scripts/next-release-tag.sh mirror beta test/fixtures/versions-stable-behind-rc.json test/fixtures/tags-existing.txt
  [ "$status" -eq 2 ]
}

@test "rejects a versions file whose head is not an upstream version" {
  run --separate-stderr bash -c 'echo "{\"stable\":{\"version\":\"latest\"}}" > "$BATS_TEST_TMPDIR/bad.json"; scripts/next-release-tag.sh mirror stable "$BATS_TEST_TMPDIR/bad.json" test/fixtures/tags-existing.txt'
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"not an upstream version"* ]]
}
