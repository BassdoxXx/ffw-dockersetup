# CrowdSec Firewall Bouncer Installation

Diese Anleitung beschreibt die Installation und Konfiguration des CrowdSec Firewall Bouncers in einer Docker-Umgebung.

## Installation

1. **Verzeichnisse vorbereiten**:
   ```bash
   mkdir -p ./configs/crowdsec/bouncers
   ```

2. **Bouncer-API-Schlüssel generieren**:
   ```bash
   docker exec crowdsec cscli bouncers add firewall-bouncer
   ```
   Kopiere den generierten API-Schlüssel.

3. **Umgebungsvariablen setzen**:
   Füge in deine `.env`-Datei folgende Zeile hinzu:
   ```
   BOUNCER_API_KEY=dein-generierter-api-schlüssel
   ```

4. **Bouncer starten**:
   ```bash
   docker compose up -d crowdsec-firewall-bouncer
   ```

## Problembehebung: Bild nicht gefunden

Falls die Fehlermeldung "repository does not exist" erscheint:

```
Error response from daemon: pull access denied for crowdsecurity/cs-firewall-bouncer, repository does not exist
```

Das liegt daran, dass das Image `crowdsecurity/cs-firewall-bouncer` nicht existiert. Das korrekte Image ist `crowdsecurity/firewall-bouncer`.

**Korrektur:**

1. Stelle sicher, dass in der `docker-compose.yaml` das korrekte Image verwendet wird:
   ```yaml
   crowdsec-firewall-bouncer:
     image: crowdsecurity/firewall-bouncer:latest
   ```

2. Überprüfe die Konfigurationsdatei und API-Schlüssel:
   ```bash
   # API-Schlüssel generieren (falls noch nicht vorhanden)
   docker exec crowdsec cscli bouncers add firewall-bouncer
   
   # API-Schlüssel in .env-Datei speichern
   echo "BOUNCER_API_KEY=dein-generierter-api-schlüssel" >> .env
   ```

3. Bouncer neu starten:
   ```bash
   docker compose up -d crowdsec-firewall-bouncer
   ```

## Überwachung und Verwaltung

1. **Logs anzeigen**:
   ```bash
   docker logs crowdsec-firewall-bouncer
   ```

2. **Blockierte IPs anzeigen**:
   ```bash
   docker exec crowdsec cscli decisions list
   ```

3. **Metriken anzeigen**:
   ```bash
   docker exec crowdsec cscli metrics show bouncers
   ```

4. **IP manuell blockieren**:
   ```bash
   docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 24h --reason "Manuelle Blockierung"
   ```

5. **IP von der Blockliste entfernen**:
   ```bash
   docker exec crowdsec cscli decisions delete --ip 1.2.3.4
   ```

## Konfigurationsdateien

- `./configs/crowdsec/bouncers/config.yaml`: Haupt-Konfigurationsdatei des Bouncers
  
  Wichtige Einstellungen:
  - `mode: iptables`: Firewall-Modus (iptables, nftables, ipset, pf)
  - `update_frequency`: Wie oft neue Blockierungen abgerufen werden
  - `iptables_chains`: Zu welchen Chains die Regeln hinzugefügt werden
  - `log_level`: Log-Level (info, debug, error, etc.)
  - `deny_action`: Aktion für blockierte IPs (DROP, REJECT)

## Fehlerbehebung

Wenn der Bouncer nicht korrekt funktioniert:

1. Überprüfe, ob CrowdSec läuft:
   ```bash
   docker ps | grep crowdsec
   ```

2. Überprüfe den API-Schlüssel:
   ```bash
   docker exec crowdsec cscli bouncers list
   ```

3. Überprüfe die Bouncer-Logs:
   ```bash
   docker logs crowdsec-firewall-bouncer
   ```

4. Überprüfe die Firewall-Regeln:
   ```bash
   docker exec crowdsec-firewall-bouncer iptables -L -n
   ```
