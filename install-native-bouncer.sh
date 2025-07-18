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

# Get CrowdSec container IP and check if port mapping is configured
echo "Step 5: Verbindung zum CrowdSec-Container konfigurieren..."
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crowdsec 2>/dev/null || echo "")
PORT_MAPPED=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if eq $p "8080/tcp"}}{{range $conf}}true{{end}}{{end}}{{end}}' crowdsec 2>/dev/null | grep -c "true" || echo "0")

# Check if port mapping exists
if [ "$PORT_MAPPED" -gt 0 ]; then
    echo "Port-Mapping für 8080 erkannt, verwende localhost:8080"
    API_URL="http://localhost:8080"
elif [ -n "$CONTAINER_IP" ]; then
    # Container IP found, use direct container access
    API_URL="http://${CONTAINER_IP}:8080"
    echo "CrowdSec direkte Container IP: $API_URL"
else
    # No container IP and no port mapping
    echo "CrowdSec-Container nicht gefunden oder kein Port-Mapping vorhanden."
    echo "Bitte gib die URL zur CrowdSec API manuell ein."
    read -p "API-URL (z.B. http://localhost:8080 oder http://172.17.0.2:8080): " API_URL
fi

# Verify API connection
echo "Prüfe Verbindung zur CrowdSec API..."
CURL_OUTPUT=$(curl -s -v "$API_URL/health" 2>&1)
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -eq 0 ]; then
    echo "Verbindung zur CrowdSec API erfolgreich: $API_URL"
    
    # Test more endpoints to make sure API is fully functional
    echo "Teste weitere API-Endpunkte..."
    DECISIONS_TEST=$(curl -s -f "$API_URL/v1/decisions" -H "X-Api-Key: DUMMY_KEY" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Warnung: Konnte nicht auf den Decisions-Endpunkt zugreifen."
        echo "Das könnte auf ein Problem mit der API hindeuten."
    else
        echo "API-Endpunkt /v1/decisions erfolgreich getestet."
    fi
else
    echo "Warnung: Konnte keine Verbindung zur CrowdSec API herstellen: $API_URL"
    echo "Fehler-Details:"
    echo "$CURL_OUTPUT"
    echo ""
    echo "Prüfe, ob der Container läuft:"
    docker ps | grep crowdsec || echo "CrowdSec-Container nicht gefunden!"
    echo ""
    echo "Überprüfe, ob der Container läuft und die API erreichbar ist."
    read -p "Trotzdem fortfahren? (j/n): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[jJyY]$ ]]; then
        echo "Installation abgebrochen."
        exit 1
    fi
fi

# Generate API key for the bouncer or get existing one
echo "Step 6: API-Schlüssel für Bouncer prüfen/generieren..."

# Check if bouncer already exists
BOUNCER_EXISTS=$(docker exec crowdsec cscli bouncers list -o raw | grep -c "cs-firewall-bouncer" || true)

if [ "$BOUNCER_EXISTS" -gt 0 ]; then
    echo "Bouncer existiert bereits, bestehenden Schlüssel abrufen..."
    # Delete and recreate the bouncer to get a fresh API key
    docker exec crowdsec cscli bouncers delete cs-firewall-bouncer
    echo "Alter Bouncer gelöscht, neuen erstellen..."
fi

# Create new bouncer and save output to a file for inspection
docker exec crowdsec cscli bouncers add cs-firewall-bouncer > /tmp/bouncer_output.txt 2>&1

if [ $? -ne 0 ]; then
    echo "Fehler beim Generieren des API-Schlüssels! Ausgabe:"
    cat /tmp/bouncer_output.txt
    exit 1
fi

# Extract actual key from output with more robust method
echo "Extrahiere API-Schlüssel..."
cat /tmp/bouncer_output.txt
API_KEY=$(cat /tmp/bouncer_output.txt | grep -o "API key for.*: .*" | sed 's/.*: //')

if [ -z "$API_KEY" ]; then
    echo "Konnte API-Schlüssel nicht extrahieren. Bitte gib ihn manuell ein."
    echo "Ausgabe des Befehls:"
    cat /tmp/bouncer_output.txt
    read -p "API-Schlüssel: " API_KEY
fi

# Display key for verification (safely, hiding most characters)
DISPLAY_KEY="${API_KEY:0:4}...${API_KEY: -4}"
echo "API-Schlüssel (teilweise): $DISPLAY_KEY"

# Update bouncer configuration
echo "Step 7: Bouncer-Konfiguration aktualisieren..."
CONFIG_FILE="/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml"

# Backup original config
cp $CONFIG_FILE ${CONFIG_FILE}.bak

# Update configuration
sed -i "s|api_url:.*|api_url: $API_URL|" $CONFIG_FILE
sed -i "s|api_key:.*|api_key: \"$API_KEY\"|" $CONFIG_FILE  # Make sure API key is quoted

# Debug output to verify configuration
echo "Checking configuration..."
crowdsec-firewall-bouncer -c $CONFIG_FILE -t

echo "Step 8: Teste Bouncer im Debug-Modus..."
echo "Teste den Bouncer zuerst im Vordergrund (für 5 Sekunden)..."
echo "Dies hilft, direkte Fehlermeldungen zu sehen."
timeout 5 crowdsec-firewall-bouncer -c $CONFIG_FILE -d || true

echo "Step 9: Bouncer als Service aktivieren und starten..."
if ! systemctl enable crowdsec-firewall-bouncer; then
    echo "Warnung: Fehler beim Aktivieren des Services. Versuche manuell mit:"
    echo "sudo systemctl enable crowdsec-firewall-bouncer"
else
    echo "Service erfolgreich aktiviert."
fi

if ! systemctl restart crowdsec-firewall-bouncer; then
    echo "Warnung: Fehler beim Neustart des Services."
    echo "Versuche Fehler zu diagnostizieren:"
    
    echo "1. Prüfe Konfiguration..."
    crowdsec-firewall-bouncer -c $CONFIG_FILE -t
    
    echo "2. Prüfe Berechtigungen der Konfigurationsdatei..."
    ls -la $CONFIG_FILE
    
    echo "3. Prüfe manuellen Start..."
    echo "Starte Bouncer manuell im Debug-Modus für 5 Sekunden:"
    timeout 5 crowdsec-firewall-bouncer -c $CONFIG_FILE -d || true
    
    echo "Service konnte nicht gestartet werden. Versuche später manuell mit:"
    echo "sudo systemctl restart crowdsec-firewall-bouncer"
else
    echo "Service erfolgreich neu gestartet."
fi

echo "Step 9: Status und Logs überprüfen..."
systemctl status crowdsec-firewall-bouncer --no-pager || true

echo "Letzte Logs (für Fehlerdiagnose):"
journalctl -u crowdsec-firewall-bouncer -n 20 --no-pager || true

echo "============================================================"
echo "Installation abgeschlossen!"
echo "============================================================"
echo ""
echo "Test mit: docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 10m --reason \"Test\""
echo "Status prüfen mit: systemctl status crowdsec-firewall-bouncer"
echo "Logs anzeigen mit: journalctl -u crowdsec-firewall-bouncer -f"
echo ""
echo "Konfiguration überprüfen mit: crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t"
echo "Debuggen mit: sudo crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -d"
echo ""
echo "Bei Problemen kann die folgende Befehlssequenz helfen:"
echo "1. sudo systemctl stop crowdsec-firewall-bouncer"
echo "2. sudo crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -d"
echo ""
