# CrowdSec Firewall Bouncer Docker

Docker image for [CrowdSec Firewall Bouncer](https://github.com/crowdsecurity/cs-firewall-bouncer), based on Alpine.

## What this image does

- Runs `crowdsec-firewall-bouncer` in a container.
- Substitutes environment variables in `/config/crowdsec-firewall-bouncer.yaml` at startup.

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Newest stable release |
| `stable` | Same as `latest` |
| `rc` | Newest release overall (including release candidates; equals the stable image when no newer RC exists) |
| `vX.Y.Z` | Immutable stable version |
| `vX.Y.Z-rcN` | Immutable release candidate |
| `vX.Y.Z-patchN` | Image-only rebuild of `vX.Y.Z` (git tag `vX.Y.Z+patchN`) |

`latest` never points at a release candidate. When one sync moves both channels to different versions it creates two releases, each publishing in its own run, so `rc` and `stable` can briefly disagree.

## Runtime requirements

- `network_mode: host`
- `cap_add: [NET_ADMIN, NET_RAW]`
- Config file mounted at `/config/crowdsec-firewall-bouncer.yaml`

## Docker Compose

```yaml
services:
  crowdsec-firewall-bouncer:
    image: ghcr.io/shgew/cs-firewall-bouncer-docker:stable
    container_name: crowdsec-firewall-bouncer
    network_mode: host
    # To run as a non-root user, add: user: "1000:1000"
    # and remove the security_opt block (no-new-privileges blocks file capabilities).
    cap_add:
      - NET_ADMIN
      - NET_RAW
    security_opt:
      - no-new-privileges:true
    environment:
      API_URL: ${API_URL}
      API_KEY: ${API_KEY}
    volumes:
      - ./config/crowdsec-firewall-bouncer.yaml:/config/crowdsec-firewall-bouncer.yaml:ro
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
```

## Configuration

Start from the upstream example config:
https://github.com/crowdsecurity/cs-firewall-bouncer/blob/main/config/crowdsec-firewall-bouncer.yaml

At startup, the entrypoint runs `envsubst` (GNU gettext) on the config file. Placeholders like `${API_KEY}` are replaced with values from container environment variables. All `${VAR}` references are substituted; undefined variables become empty strings.

Example:

- Config: `api_key: ${API_KEY}`
- Container env: `API_KEY=abc123`
- Runtime config: `api_key: abc123`

## Release flow

A daily sync reads the upstream release list, picks the head of each channel, and pins the version plus per-arch tarball sha256 into `versions.json`.

Channels come from the shape of the upstream tag, not from GitHub's prerelease checkbox. Upstream sets that flag inconsistently (`v0.0.32` and `v0.0.36` are both bare releases flagged as prereleases), so it is ignored.

- `vX.Y.Z` is the stable channel head, and the rc head too when it is the newest upstream tag.
- `vX.Y.Z-rcN` is the rc channel head.

A repo release tag is the upstream tag, character for character. Mirroring an upstream release never adds a suffix, and `scripts/next-release-tag.sh mirror` refuses a version that is already tagged.

When a channel head changes, the sync builds both architectures and runs `scripts/smoke-test.sh` before it commits. A failed build or smoke test means no commit, no release, and no image. The smoke test executes the amd64 image; arm64 is built and checksum-verified but not run.

The `RELEASE_TOKEN` repo secret (a PAT with `contents:write` scope) is required. GitHub does not trigger `release: published` workflow events for releases created with the default `GITHUB_TOKEN`, so releases must be created with a PAT.

## Patch releases

`+patchN` means the container changed and the upstream binary did not. Run the "Cut Patch Release" workflow from the Actions tab, pick the channel, and describe what changed in the image. It reads the existing tags and picks the next number, so patch numbers are never typed by hand.

The workflow refuses a channel head this repository has never released. Patch 1 of a version with no mirror release would be a mirror release wearing the wrong tag.

`scripts/release-plan.sh` rejects a release tag whose version is not the current channel head in `versions.json`, with `update versions.json first`.

## Local testing

Run unit tests:

```sh
bats test/
```

Build and smoke-test the stable image:

```sh
docker build \
  --build-arg CS_FIREWALL_BOUNCER_VERSION=v0.0.36 \
  --build-arg CS_TARBALL_SHA256_AMD64=sha256:f86e4b72693549d99f40a9402abefb894108f047a3fbe6e72fada25ee17ce88b \
  --build-arg CS_TARBALL_SHA256_ARM64=sha256:ce184d3b1ae5888189d237bb0ff1d2414be2ef12729750a7321a4abd2d253de6 \
  -t local/csfb:stable-test .
scripts/smoke-test.sh local/csfb:stable-test v0.0.36
```

Preview the tag a channel would get next:

```sh
git tag | scripts/next-release-tag.sh mirror stable versions.json -
git tag | scripts/next-release-tag.sh patch stable versions.json -
```

Every workflow has a dry run that stops short of writing anything. In the Actions tab: "Build and Publish Docker Image" via workflow dispatch builds and smoke-tests both channels without pushing; "Check Upstream Release" with `dry_run: true` resolves upstream and, when a channel head actually moved, builds and smoke-tests it without committing; "Cut Patch Release" with `dry_run: true` computes the tag and gates on a build without creating the release.

Post-release check:

```sh
docker buildx imagetools inspect ghcr.io/shgew/cs-firewall-bouncer-docker:stable
```

## Firewall backend note

Docker Engine uses `iptables` by default. Native `nftables` mode in Docker is still [experimental](https://docs.docker.com/engine/network/firewall-nftables/).

More context: https://github.com/shgew/cs-firewall-bouncer-docker/issues/6

## License

This project is licensed under the MIT License.
