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

`latest` never points at a release candidate. The `rc` alias may lag a few minutes while both channels publish after a sync.

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

A daily sync reads upstream releases (stable and prereleases), pins versions and per-arch sha256 checksums into `versions.json`, commits, and creates a repo release. A prerelease-flagged release triggers the RC channel build; a normal release triggers the stable channel build.

The `RELEASE_TOKEN` repo secret (a PAT with `contents:write` scope) is required. GitHub does not trigger `release: published` workflow events for releases created with the default `GITHUB_TOKEN`, so releases must be created with a PAT.

## Patch releases

To rebuild an image for an existing upstream version without changing the upstream binary:

1. Ensure `versions.json` has the target version as the channel head.
2. Tag the commit as `vX.Y.Z+patchN` (stable) or `vX.Y.Z-rcN+patchM` (RC, created as prerelease).
3. Create a GitHub release from that tag.

The publish workflow rejects patches of non-head versions with `update versions.json first`.

## Local testing

Run unit tests:

```sh
bats test/
```

Build and smoke-test the stable image:

```sh
docker build \
  --build-arg CS_FIREWALL_BOUNCER_VERSION=v0.0.34 \
  --build-arg CS_TARBALL_SHA256_AMD64=sha256:8b07e08fb35a90b33eb2403eb93966679b39adb42c9cd03882de66cdf19a949f \
  --build-arg CS_TARBALL_SHA256_ARM64=sha256:41899de18ad928e89de26a6fcd46ae8c7cb9a3b95369e850335106db0bf727aa \
  -t local/csfb:stable-test .
scripts/smoke-test.sh local/csfb:stable-test v0.0.34
```

Dry-run the publish workflow (builds both channels without pushing): open the Actions tab, select "Build and Publish Docker Image", and run it via workflow dispatch.

Dry-run the sync workflow (detects upstream changes without committing): open the Actions tab, select "Check Upstream Release", and run it with `dry_run: true`.

Post-release check:

```sh
docker buildx imagetools inspect ghcr.io/shgew/cs-firewall-bouncer-docker:stable
```

## Firewall backend note

Docker Engine uses `iptables` by default. Native `nftables` mode in Docker is still [experimental](https://docs.docker.com/engine/network/firewall-nftables/).

More context: https://github.com/shgew/cs-firewall-bouncer-docker/issues/6

## License

This project is licensed under the MIT License.
