# Einfache Anleitung für CrowdSec Firewall Bouncer

Diese vereinfachte Anleitung sollte den Firewall Bouncer erfolgreich zum Laufen bringen.

## 1. Konfigurationsdatei prüfen

Lasse uns zuerst den Inhalt der aktuellen Bouncer-Konfigurationsdatei anzeigen:

```bash
sudo cat /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

## 2. Konfigurationsdatei korrigieren

Erstelle eine neue, einfache Konfigurationsdatei:

```bash
# Aktuelle Konfiguration sichern
sudo cp /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.bak

# Neue Konfiguration erstellen
sudo bash -c 'cat > /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml << EOF
# Firewall Bouncer Konfiguration
mode: iptables
update_frequency: 10s
daemonize: false
log_mode: file
log_dir: /var/log/
log_level: info

api_url: http://172.18.0.8:8080
api_key: "DEIN_API_KEY_HIER"

iptables_chains:
  - INPUT
  - FORWARD
  - DOCKER-USER

deny_action: DROP
deny_log: true
deny_log_prefix: "crowdsec: "

blacklists_ipv4: crowdsec-blacklists
blacklists_ipv6: crowdsec6-blacklists
EOF'
```

## 3. Neuen API-Schlüssel generieren

```bash
# Lösche den alten Bouncer (falls vorhanden)
docker exec crowdsec cscli bouncers delete cs-firewall-bouncer

# Erstelle einen neuen Bouncer und API-Schlüssel
docker exec crowdsec cscli bouncers add cs-firewall-bouncer
```

Kopiere den generierten API-Schlüssel und füge ihn in die Konfigurationsdatei ein:

```bash
sudo sed -i 's/DEIN_API_KEY_HIER/dein-echter-api-schlüssel/' /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

## 4. Konfiguration testen

```bash
sudo crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t
```

## 5. Service neu starten

```bash
sudo systemctl restart crowdsec-firewall-bouncer
```

## 6. Status prüfen

```bash
sudo systemctl status crowdsec-firewall-bouncer
```

## 7. Logs überprüfen bei Problemen

```bash
sudo journalctl -u crowdsec-firewall-bouncer -f
```

## 8. Testen der Blockierungsfunktion

```bash
# Testblockierung hinzufügen
docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 10m --reason "Test"

# Prüfen, ob die IP in den Blockierungen erscheint
docker exec crowdsec cscli decisions list

# Prüfen, ob die IP in der Firewall blockiert ist
sudo ipset list crowdsec-blacklists
```
