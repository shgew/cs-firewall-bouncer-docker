#!/bin/sh
set -eu

CONFIG_SRC="/config/crowdsec-firewall-bouncer.yaml"
CONFIG_RENDERED="/tmp/crowdsec/crowdsec-firewall-bouncer.yaml"

if [ ! -f "$CONFIG_SRC" ]; then
    echo "ERROR: config not found at $CONFIG_SRC - mount it (see README)" >&2
    exit 1
fi

mkdir -p /tmp/crowdsec
envsubst < "$CONFIG_SRC" > "$CONFIG_RENDERED"

exec crowdsec-firewall-bouncer -c "$CONFIG_RENDERED"
