# CrowdSec Configuration

Diese Verzeichnisstruktur enthält alle Konfigurationsdateien für CrowdSec und den Firewall Bouncer.

## Directory Structure

- `config/`: CrowdSec-Konfigurationsdateien, die nach /etc/crowdsec gemountet werden
- `data/`: CrowdSec-Datendateien
- `bouncers/`: Konfigurationsdateien für Bouncer-Komponenten

## Setup Instructions

### Log File Permissions

CrowdSec needs read access to system log files. To grant this access:

1. Create a `logreader` group on the host system:
```bash
sudo groupadd logreader
```

2. Find the GID of the group:
```bash
getent group logreader
# Example output: logreader:x:1001:
```

3. Make sure the GID in docker-compose.yaml matches:
```yaml
crowdsec:
  # ... other configuration ...
  group_add:
    - "1001"  # Replace with the actual GID of the logreader group
```

4. Give the logreader group read access to log files:
```bash
# Set group ownership
sudo find /var/log -type f -exec chgrp logreader {} \; 2>/dev/null || true
sudo find /var/log -type d -exec chgrp logreader {} \; 2>/dev/null || true

# Set read permissions
sudo find /var/log -type f -exec chmod g+r {} \; 2>/dev/null || true
sudo find /var/log -type d -exec chmod g+rx {} \; 2>/dev/null || true
```

5. Restart CrowdSec:
```bash
docker compose restart crowdsec
```

## Important Note

All configuration files should be placed in the `config/` directory, including:
- `config/acquis.yaml`: Defines the log sources to monitor
- Other CrowdSec configuration files

The current setup mounts `./configs/crowdsec/config` to `/etc/crowdsec` in the container

## Monitoring Log Files

The following log files are currently monitored:
- System logs (fail2ban, alternatives, dpkg)
- System journal files
- Nginx logs (when present)
- Docker container logs

To check which logs are being monitored:
```bash
docker exec crowdsec cscli metrics
```

## Bouncer Setup

CrowdSec benötigt einen Bouncer, um erkannte Bedrohungen aktiv zu blockieren. Ohne Bouncer werden Angriffe nur erkannt, aber nicht blockiert.

### Firewall-Bouncer Installation

1. Füge den Bouncer zur Docker-Compose-Datei hinzu:
```yaml
  crowdsec-firewall-bouncer:
    image: crowdsecurity/crowdsec-firewall-bouncer:latest
    container_name: crowdsec-firewall-bouncer
    restart: unless-stopped
    environment:
      - BOUNCER_KEY_FILE=/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.key
      - BACKEND=iptables
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./configs/crowdsec/bouncers:/etc/crowdsec/bouncers
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    depends_on:
      - crowdsec
```

2. Erstelle zuerst das bouncers Verzeichnis:
```bash
mkdir -p ./configs/crowdsec/bouncers
```

3. Generiere einen Bouncer-API-Schlüssel:
```bash
docker exec crowdsec cscli bouncers add firewall-bouncer
```

4. Kopiere den generierten API-Schlüssel in die Bouncer-Konfiguration:
```bash
# Ersetze BOUNCER_KEY mit dem generierten Schlüssel
sudo tee ./configs/crowdsec/bouncers/crowdsec-firewall-bouncer.key > /dev/null << EOT
BOUNCER_KEY
EOT
```

5. Starte den Bouncer:
```bash
docker compose up -d crowdsec-firewall-bouncer
```

### Überwachen der Blockierungen

Nach der Einrichtung des Bouncers kannst du blockierte IPs überprüfen:

```bash
docker exec crowdsec cscli decisions list
```

## Notes

When updating configurations, simply update the files in this directory and restart CrowdSec:

```bash
docker compose restart crowdsec
```
