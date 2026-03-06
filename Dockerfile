FROM alpine:3.21

ARG TARGETARCH
ARG CS_FIREWALL_BOUNCER_VERSION

RUN apk add --no-cache \
    nftables ipset iptables \
    envsubst \
    libcap-setcap

RUN wget -qO - \
    "https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_FIREWALL_BOUNCER_VERSION}/crowdsec-firewall-bouncer-linux-${TARGETARCH}.tgz" \
    | tar -xz -C /tmp/ \
    && mv /tmp/crowdsec-firewall-bouncer*/crowdsec-firewall-bouncer /usr/local/bin/crowdsec-firewall-bouncer \
    && chmod +x /usr/local/bin/crowdsec-firewall-bouncer \
    && rm -rf /tmp/crowdsec-firewall-bouncer*

RUN setcap cap_net_admin,cap_net_raw+ep /usr/sbin/xtables-nft-multi && \
    setcap cap_net_admin,cap_net_raw+ep /usr/sbin/ipset && \
    chmod 1777 /run

COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
