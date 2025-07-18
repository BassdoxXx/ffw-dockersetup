#!/bin/bash
#
# Installation script for native CrowdSec Firewall Bouncer
#
# This script helps install and configure the CrowdSec Firewall Bouncer
# on the host system to work with the CrowdSec Docker container
#

set -e

echo "============================================================"
echo "CrowdSec Native Firewall Bouncer - Installation Script"
echo "============================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als Root-Benutzer ausführen (sudo)!"
  exit 1
fi

# Add CrowdSec repository
echo "Step 1: Repository-Quellen hinzufügen..."
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash

# Update package list
echo "Step 2: Paketlisten aktualisieren..."
apt update

# Prompt for firewall type
echo "Step 3: Wähle Firewall-Backend..."
PS3="Wähle deine Firewall (1-2): "
select fw in "iptables" "nftables"; do
    case $fw in
        iptables)
            echo "iptables ausgewählt"
            BOUNCER_PKG="crowdsec-firewall-bouncer-iptables"
            break
            ;;
        nftables)
            echo "nftables ausgewählt"
            BOUNCER_PKG="crowdsec-firewall-bouncer-nftables"
            break
            ;;
        *) echo "Ungültige Auswahl $REPLY";;
    esac
done

# Install the bouncer package
echo "Step 4: $BOUNCER_PKG installieren..."
apt install -y $BOUNCER_PKG

# Get CrowdSec container IP
echo "Step 5: IP-Adresse des CrowdSec-Containers ermitteln..."
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crowdsec)

if [ -z "$CONTAINER_IP" ]; then
    echo "CrowdSec-Container nicht gefunden. Stelle sicher, dass er läuft!"
    echo "Alternativ: Benutze 'localhost' wenn Port-Mapping konfiguriert ist."
    read -p "API-URL (z.B. http://localhost:8080 oder http://172.17.0.2:8080): " API_URL
else
    API_URL="http://${CONTAINER_IP}:8080"
    echo "CrowdSec API-URL: $API_URL"
fi

# Generate API key for the bouncer
echo "Step 6: API-Schlüssel für Bouncer generieren..."
API_KEY=$(docker exec crowdsec cscli bouncers add cs-firewall-bouncer)

if [ $? -ne 0 ]; then
    echo "Fehler beim Generieren des API-Schlüssels!"
    exit 1
fi

# Extract actual key from output
API_KEY=$(echo "$API_KEY" | grep -oP 'API key for.*: \K.*')

# Update bouncer configuration
echo "Step 7: Bouncer-Konfiguration aktualisieren..."
CONFIG_FILE="/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml"

# Backup original config
cp $CONFIG_FILE ${CONFIG_FILE}.bak

# Update configuration
sed -i "s|api_url:.*|api_url: $API_URL|" $CONFIG_FILE
sed -i "s|api_key:.*|api_key: $API_KEY|" $CONFIG_FILE

echo "Step 8: Bouncer neustarten und aktivieren..."
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
