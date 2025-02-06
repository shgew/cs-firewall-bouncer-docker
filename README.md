# CrowdSec Firewall Bouncer Docker

This repository provides a Dockerized version of the [CrowdSec Firewall Bouncer](https://github.com/crowdsecurity/cs-firewall-bouncer), specifically for users who cannot install the firewall package directly on their system. This containerized approach allows the bouncer to run independently, making it suitable for environments like TrueNAS SCALE.

## Features
- Supports **nftables** only.
- Officially supports **Debian**, but **Alpine** has been tested and works without issues.
- Allows environment variable substitution in the passed configuration file.

## Requirements
For the container to function correctly, the following settings are required:
- `network_mode: host`
- `cap_add: NET_ADMIN`
- A valid configuration file mapped to `/config/crowdsec-firewall-bouncer.yaml`.

## Docker Compose Example
Below is an example `docker-compose.yml` configuration for deploying the firewall bouncer:

```yaml
services:
  firewall-bouncer:
    image: ghcr.io/shgew/cs-firewall-bouncer-docker:latest
    container_name: crowdsec-firewall-bouncer
    network_mode: host
    cap_add:
      - NET_ADMIN
    environment:
      API_URL: ${API_URL}
      API_KEY: ${API_KEY}
    volumes:
      - ./config/crowdsec-firewall-bouncer.yaml:/config/crowdsec-firewall-bouncer.yaml:ro
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
```

## Configuration
The configuration file must be mapped to `/config/crowdsec-firewall-bouncer.yaml` inside the container. Additionally, any environment variables used within the configuration file will be automatically substituted with their corresponding values.

A good starting point: https://github.com/crowdsecurity/cs-firewall-bouncer/blob/main/config/crowdsec-firewall-bouncer.yaml

## Usage
1. Create a valid `docker-compose.yml` configuration file.
2. Create a valid `crowdsec-firewall-bouncer.yaml` configuration file inside the `config` directory.
3. Start the container using Docker Compose:
   ```sh
   docker-compose up -d
   ```
4. Verify that the bouncer is running properly:
   ```sh
   docker logs -f crowdsec-firewall-bouncer
   ```

## Notes
- This container is built primarily for systems that cannot install the firewall package directly, such as **TrueNAS Scale**.
- If you encounter any issues, please check the logs and ensure all environment variables are set correctly.

## License
This project is licensed under the MIT License.

