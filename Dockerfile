FROM alpine:latest

ARG TARGETARCH
ARG CS_FIREWALL_BOUNCER_VERSION

RUN wget -qO - \
    "https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_FIREWALL_BOUNCER_VERSION}/crowdsec-firewall-bouncer-linux-${TARGETARCH}.tgz" \
    | tar -xz -C /tmp/ \
    && mv "/tmp/crowdsec-firewall-bouncer-${CS_FIREWALL_BOUNCER_VERSION}/crowdsec-firewall-bouncer" /usr/local/bin/crowdsec-firewall-bouncer \
    && chmod +x /usr/local/bin/crowdsec-firewall-bouncer

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
