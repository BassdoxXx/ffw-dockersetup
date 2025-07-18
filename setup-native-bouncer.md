# Native CrowdSec Firewall Bouncer Installation Guide

Dieses Dokument beschreibt die native Installation des CrowdSec Firewall Bouncers auf dem Hostsystem (nicht in Docker).

## 1. Repository-Konfiguration

Füge die CrowdSec-Repository-Quellen zu deinem System hinzu:

```bash
# Repository-Schlüssel hinzufügen
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash

# Systempaketlisten aktualisieren
sudo apt update
```

## 2. Firewall Bouncer installieren

Wähle eine der folgenden Optionen je nach gewünschtem Firewall-Backend:

### Option A: Installation mit iptables

```bash
sudo apt install -y crowdsec-firewall-bouncer-iptables
```

### Option B: Installation mit nftables

```bash
sudo apt install -y crowdsec-firewall-bouncer-nftables
```

## 3. API-Schlüssel für Bouncer generieren

1. Einen API-Schlüssel für den Bouncer generieren:

```bash
# Mit dem CrowdSec Docker-Container
docker exec crowdsec cscli bouncers add cs-firewall-bouncer
```

2. Die Ausgabe wird etwa so aussehen:

```
API key for 'cs-firewall-bouncer': 42c9e844a5f3456d90c67791b05dd280
```

3. Kopiere den API-Schlüssel, er wird im nächsten Schritt benötigt.

## 4. Bouncer konfigurieren

1. Öffne die Konfigurationsdatei:

```bash
sudo nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

2. Aktualisiere die folgende Konfiguration:

```yaml
# URL zum CrowdSec LAPI (Local API)
api_url: http://localhost:8080

# API-Schlüssel
api_key: "HIER_DEN_GENERIERTEN_API_KEY_EINFÜGEN"

# Weitere Optionen nach Bedarf anpassen...
```

**Wichtig**: Da der CrowdSec-Server in Docker läuft, musst du sicherstellen, dass der Bouncer auf die CrowdSec-API zugreifen kann. Du hast zwei Möglichkeiten:

**Option 1**: Port Mapping für CrowdSec hinzufügen
- Aktualisiere die docker-compose.yaml, um Port 8080 zu mappen:

```yaml
crowdsec:
  # andere Konfigurationen...
  ports:
    - "127.0.0.1:8080:8080"  # Nur lokal zugänglich machen
```

**Option 2**: Netzwerkkonfiguration anpassen
- Stelle sicher, dass der Bouncer die Docker-Container IP erreichen kann:

```yaml
api_url: http://CONTAINER_IP:8080
```

Wobei `CONTAINER_IP` die IP des CrowdSec-Containers ist. Diese kannst du herausfinden mit:

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crowdsec
```

## 5. Bouncer neustarten und aktivieren

```bash
sudo systemctl restart crowdsec-firewall-bouncer
sudo systemctl enable crowdsec-firewall-bouncer
```

## 6. Status überprüfen

```bash
# Überprüfen des Service-Status
sudo systemctl status crowdsec-firewall-bouncer

# Logs anschauen
sudo journalctl -u crowdsec-firewall-bouncer -f
```

## 7. Testen der Blockierung

1. Eine IP zur Blockierung hinzufügen:

```bash
docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 1h --reason "Test"
```

2. Überprüfen, ob die IP in den Firewall-Regeln erscheint:

```bash
# Für iptables
sudo ipset list crowdsec-blacklists

# Für nftables
sudo nft list set ip crowdsec crowdsec-blacklists
```

## 8. Port-Mapping für CrowdSec hinzufügen (falls benötigt)

Wenn du dich für Option 1 unter Schritt 4 entschieden hast, muss die docker-compose.yaml aktualisiert werden:

```yaml
crowdsec:
  image: crowdsecurity/crowdsec
  container_name: crowdsec
  restart: always
  # Weitere Konfiguration...
  ports:
    - "127.0.0.1:8080:8080"  # Nur lokal zugänglich machen
  # Weitere Konfiguration...
```

Dann:

```bash
docker compose up -d crowdsec
```

## Troubleshooting

### Der Bouncer kann keine Verbindung zum CrowdSec-Container herstellen

1. Überprüfe die API-URL in der Bouncer-Konfiguration:

```bash
cat /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml | grep api_url
```

2. Teste die Verbindung:

```bash
curl -v http://IP:8080/
```

3. Überprüfe die Firewall-Konfiguration:

```bash
sudo ufw status
# oder
sudo iptables -L
```

### Bouncer startet nicht

1. Überprüfe die Logs:

```bash
sudo journalctl -u crowdsec-firewall-bouncer -n 50
```

2. Überprüfe die Konfiguration:

```bash
sudo crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t
```

## Weitere Informationen

- [Offizielle CrowdSec Firewall-Bouncer-Dokumentation](https://docs.crowdsec.net/docs/bouncers/firewall/)
- [CrowdSec GitHub Repository](https://github.com/crowdsecurity/cs-firewall-bouncer)
