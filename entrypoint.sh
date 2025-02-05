#!/bin/sh

# Replace environment variables in config
mkdir -p /etc/crowdsec/bouncers
envsubst < /config/crowdsec-firewall-bouncer.yaml > /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml

# Start the bouncer
exec crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
