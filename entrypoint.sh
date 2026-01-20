#!/bin/sh

# Replace environment variables in config
mkdir -p /tmp/crowdsec
envsubst < /config/crowdsec-firewall-bouncer.yaml > /tmp/crowdsec/crowdsec-firewall-bouncer.yaml

# Start the bouncer
exec crowdsec-firewall-bouncer -c /tmp/crowdsec/crowdsec-firewall-bouncer.yaml
