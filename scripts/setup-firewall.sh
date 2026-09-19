#!/usr/bin/env bash
# scripts/setup-firewall.sh
#
# Configures ufw for the relay host: deny inbound by default, allow SSH and
# the HTTP/HTTPS ports Caddy uses for ACME and WebSocket traffic.

set -euo pipefail

sudo apt-get update
sudo apt-get install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp comment 'ssh'

# ACME HTTP-01 challenge and HTTP->HTTPS redirect
sudo ufw allow 80/tcp comment 'http (acme)'

# HTTPS / WebSocket
sudo ufw allow 443/tcp comment 'https'
sudo ufw allow 443/udp comment 'https (http3 quic)'

sudo ufw --force enable

echo
sudo ufw status verbose