FROM alpine:latest

ARG TARGETARCH
ARG CS_FIREWALL_BOUNCER_VERSION

# Install dependencies
RUN apk add --no-cache \
    # for the firewall
    nftables ipset iptables \
    # for templating
    envsubst \
    # for capabilities
    libcap-setcap

# Install the firewall
RUN wget -qO - \
    "https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_FIREWALL_BOUNCER_VERSION}/crowdsec-firewall-bouncer-linux-${TARGETARCH}.tgz" \
    | tar -xz -C /tmp/ \
    && mv /tmp/crowdsec-firewall-bouncer*/crowdsec-firewall-bouncer /usr/local/bin/crowdsec-firewall-bouncer \
    && chmod +x /usr/local/bin/crowdsec-firewall-bouncer

# Apply capabilities to the ACTUAL binaries, not the symlinks
RUN setcap cap_net_admin,cap_net_raw+ep /usr/sbin/xtables-nft-multi && \
    setcap cap_net_admin,cap_net_raw+ep /usr/sbin/ipset

# needed so non-root user can create xtables lock file
RUN chmod o+w /run

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
