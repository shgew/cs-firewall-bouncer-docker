# CrowdSec Firewall Bouncer Docker

Docker image for [CrowdSec Firewall Bouncer](https://github.com/crowdsecurity/cs-firewall-bouncer), based on Alpine.

## What this image does

- Runs `crowdsec-firewall-bouncer` in a container.
- Substitutes environment variables in `/config/crowdsec-firewall-bouncer.yaml` at startup.

## Runtime requirements

- `network_mode: host`
- `cap_add: [NET_ADMIN, NET_RAW]`
- Config file mounted at `/config/crowdsec-firewall-bouncer.yaml`

## Docker Compose

```yaml
services:
  crowdsec-firewall-bouncer:
    image: ghcr.io/shgew/cs-firewall-bouncer-docker:latest
    container_name: crowdsec-firewall-bouncer
    network_mode: host
    # Optional non-root mode:
    # user: 1000:1000
    cap_add:
      - NET_ADMIN
      - NET_RAW
    security_opt: # In non-root mode, remove this block.
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

- https://github.com/crowdsecurity/cs-firewall-bouncer/blob/main/config/crowdsec-firewall-bouncer.yaml

At startup, the entrypoint runs `envsubst` on the config file.
Placeholders like `${API_KEY}` are replaced with values from container
environment variables before the bouncer starts.

Example:

- Config: `api_key: ${API_KEY}`
- Container env: `API_KEY=abc123`
- Final runtime config: `api_key: abc123`

## Usage

1. Choose an image tag from [published packages](https://github.com/shgew/cs-firewall-bouncer-docker/pkgs/container/cs-firewall-bouncer-docker).
2. Create `./config/crowdsec-firewall-bouncer.yaml`.
3. Start:

```sh
docker compose up -d
```

4. Check logs:

```sh
docker compose logs -f
```

## Release and version flow

- `version.txt` pins the upstream `cs-firewall-bouncer` version used during image build.
- Repository release tags can include internal suffixes (for example `v0.0.34+patch1`) without changing the pinned upstream binary version.

## Firewall backend note

Docker Engine uses `iptables` by default. Native `nftables` mode in Docker is still [experimental](https://docs.docker.com/engine/network/firewall-nftables/).

More context on backend choice: https://github.com/shgew/cs-firewall-bouncer-docker/issues/6

## License

This project is licensed under the MIT License.
