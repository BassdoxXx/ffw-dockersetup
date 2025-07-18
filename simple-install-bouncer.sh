#!/bin/bash
#
# Simple CrowdSec Firewall Bouncer Installation Script
#
# This script helps install and configure the CrowdSec Firewall Bouncer
# on the host system to work with the CrowdSec Docker container
#

set -e

echo "============================================================"
echo "Simple CrowdSec Firewall Bouncer - Installation Script"
echo "============================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als Root-Benutzer ausführen (sudo)!"
  exit 1
fi

# Add CrowdSec repository
echo "Step 1: Repository-Quellen hinzufügen..."
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash

# Update package list
echo "Step 2: Paketlisten aktualisieren..."
apt update

# Install the bouncer package
echo "Step 3: crowdsec-firewall-bouncer-iptables installieren..."
apt install -y crowdsec-firewall-bouncer-iptables

# Get CrowdSec container IP 
echo "Step 4: IP-Adresse des CrowdSec-Containers ermitteln..."
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crowdsec)
echo "CrowdSec Container IP: $CONTAINER_IP"

# Generate API key for the bouncer
echo "Step 5: API-Schlüssel für Bouncer generieren..."

# Delete the bouncer if it exists
docker exec crowdsec cscli bouncers delete cs-firewall-bouncer 2>/dev/null || true

# Create new bouncer and get API key
BOUNCER_OUTPUT=$(docker exec crowdsec cscli bouncers add cs-firewall-bouncer)
echo "$BOUNCER_OUTPUT"
API_KEY=$(echo "$BOUNCER_OUTPUT" | grep -o "API key for.*: .*" | cut -d ":" -f2 | tr -d " ")

echo "API Key: $API_KEY"

# Create a simple bouncer configuration
echo "Step 6: Bouncer-Konfiguration erstellen..."
cat > /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml << EOF
# Firewall Bouncer Konfiguration
mode: iptables
update_frequency: 10s
daemonize: false
log_mode: file
log_dir: /var/log/
log_level: info

api_url: http://${CONTAINER_IP}:8080
api_key: "${API_KEY}"

iptables_chains:
  - INPUT
  - FORWARD
  - DOCKER-USER

deny_action: DROP
deny_log: true
deny_log_prefix: "crowdsec: "

blacklists_ipv4: crowdsec-blacklists
blacklists_ipv6: crowdsec6-blacklists
EOF

echo "Step 7: Konfiguration testen..."
crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t

echo "Step 8: Service neustarten..."
systemctl restart crowdsec-firewall-bouncer
systemctl enable crowdsec-firewall-bouncer

echo "Step 9: Status überprüfen..."
systemctl status crowdsec-firewall-bouncer --no-pager

echo "============================================================"
echo "Installation abgeschlossen!"
echo "============================================================"
echo ""
echo "Test mit: docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 10m --reason \"Test\""
echo "Status prüfen mit: systemctl status crowdsec-firewall-bouncer"
echo "Logs anzeigen mit: journalctl -u crowdsec-firewall-bouncer -f"
echo ""
