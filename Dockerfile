FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

ARG TARGETARCH
ARG CS_FIREWALL_BOUNCER_VERSION
ARG CS_TARBALL_SHA256_AMD64
ARG CS_TARBALL_SHA256_ARM64

RUN apk add --no-cache nftables ipset iptables gettext-envsubst libcap-setcap

RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) CS_TARBALL_SHA256="$CS_TARBALL_SHA256_AMD64" ;; \
      arm64) CS_TARBALL_SHA256="$CS_TARBALL_SHA256_ARM64" ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    CS_TARBALL_SHA256="${CS_TARBALL_SHA256#sha256:}"; \
    if [ -z "$CS_TARBALL_SHA256" ]; then echo "missing CS_TARBALL_SHA256_* build arg" >&2; exit 1; fi; \
    wget -q -O /tmp/bouncer.tgz "https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_FIREWALL_BOUNCER_VERSION}/crowdsec-firewall-bouncer-linux-${TARGETARCH}.tgz"; \
    echo "$CS_TARBALL_SHA256  /tmp/bouncer.tgz" | sha256sum -c -; \
    tar -xzf /tmp/bouncer.tgz -C /tmp; \
    mv /tmp/crowdsec-firewall-bouncer*/crowdsec-firewall-bouncer /usr/local/bin/crowdsec-firewall-bouncer; \
    chmod +x /usr/local/bin/crowdsec-firewall-bouncer; \
    rm -rf /tmp/bouncer.tgz /tmp/crowdsec-firewall-bouncer*

RUN setcap cap_net_admin,cap_net_raw+ep /usr/sbin/xtables-nft-multi \
    && setcap cap_net_admin,cap_net_raw+ep /usr/sbin/ipset \
    && chmod 1777 /run

COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
