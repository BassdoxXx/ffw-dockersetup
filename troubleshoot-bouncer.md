# CrowdSec Firewall Bouncer - Fehlerbehebung

Dieses Dokument enthält Schritte zur Fehlerbehebung bei Problemen mit dem CrowdSec Firewall Bouncer.

## 1. Prüfe den Status des Bouncers

```bash
sudo systemctl status crowdsec-firewall-bouncer
```

## 2. Logs analysieren

```bash
sudo journalctl -u crowdsec-firewall-bouncer -n 50
```

## 3. Konfiguration überprüfen

```bash
sudo cat /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

Achte besonders auf:
- `api_url`: Sollte auf den CrowdSec-Container zeigen (z.B. `http://172.18.0.8:8080`)
- `api_key`: Sollte ein gültiger API-Schlüssel sein und in Anführungszeichen stehen
- `mode`: Sollte auf `iptables` oder `nftables` gesetzt sein, je nach deiner Wahl

## 4. API-Verbindung testen

```bash
# Test der grundlegenden Erreichbarkeit
curl -v http://172.18.0.8:8080/health

# Test der API mit dem konfigurierten Schlüssel (ersetze API_KEY)
curl -v http://172.18.0.8:8080/v1/decisions -H "X-Api-Key: API_KEY"
```

## 5. Manueller Testlauf im Debug-Modus

```bash
# Stoppe den Service zuerst
sudo systemctl stop crowdsec-firewall-bouncer

# Starte manuell im Debug-Modus 
sudo crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml --debug
```

## 6. Häufige Probleme und Lösungen

### Problem: "API-Verbindungsfehler"

Mögliche Ursachen:
- CrowdSec-Container ist nicht erreichbar
- API-URL ist falsch
- API-Key ist ungültig

Lösungen:
1. Prüfe, ob der Container läuft:
   ```bash
   docker ps | grep crowdsec
   ```
2. Prüfe, ob die IP-Adresse korrekt ist:
   ```bash
   docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' crowdsec
   ```
3. Generiere einen neuen API-Schlüssel:
   ```bash
   docker exec crowdsec cscli bouncers delete cs-firewall-bouncer
   docker exec crowdsec cscli bouncers add cs-firewall-bouncer
   ```

### Problem: "Permission denied"

Mögliche Ursachen:
- Falsche Dateiberechtigungen
- SELinux-Einschränkungen
- AppArmor-Profile

Lösungen:
1. Prüfe und korrigiere Dateiberechtigungen:
   ```bash
   sudo chmod 600 /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
   ```
2. Temporär SELinux deaktivieren (falls zutreffend):
   ```bash
   sudo setenforce 0
   ```

### Problem: "iptables/nftables Fehler"

Mögliche Ursachen:
- Fehlende Berechtigungen
- Fehlerhafte Konfiguration
- Konflikte mit bestehenden Regeln

Lösungen:
1. Prüfe, ob du die notwendigen Berechtigungen hast
2. Überprüfe, ob die richtigen Chains existieren
3. Prüfe die aktuelle Firewall-Konfiguration:
   ```bash
   # Für iptables
   sudo iptables -L
   # Für nftables
   sudo nft list tables
   ```

## 7. Neuinstallation

Wenn alles andere fehlschlägt, versuche eine vollständige Neuinstallation:

```bash
# Deinstallieren
sudo apt remove --purge crowdsec-firewall-bouncer-iptables

# Konfigurationsdateien manuell löschen
sudo rm -rf /etc/crowdsec/bouncers

# Neu installieren
sudo apt install crowdsec-firewall-bouncer-iptables
```

Führe dann das `install-native-bouncer.sh`-Skript erneut aus.

## 8. Wichtige Befehle für Tests

```bash
# Blockierung hinzufügen
docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 10m --reason "Test"

# Blockierung entfernen
docker exec crowdsec cscli decisions delete --ip 1.2.3.4

# Alle aktiven Blockierungen anzeigen
docker exec crowdsec cscli decisions list

# Prüfen, ob IP in ipset ist (für iptables)
sudo ipset list crowdsec-blacklists
```
