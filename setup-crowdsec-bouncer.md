# Schritt-für-Schritt Anleitung: CrowdSec Firewall Bouncer Einrichtung

Diese Anleitung hilft dir, den CrowdSec Firewall Bouncer korrekt einzurichten.

## 1. Überprüfen der Docker-Compose Konfiguration

Die Konfiguration in deiner `docker-compose.yaml` sollte jetzt korrekt sein und das richtige Image `crowdsecurity/firewall-bouncer` verwenden.

## 2. API-Schlüssel generieren

1. Stelle sicher, dass der CrowdSec-Container läuft:
   ```bash
   docker compose up -d crowdsec
   ```

2. Generiere einen API-Schlüssel für den Bouncer:
   ```bash
   docker exec crowdsec cscli bouncers add firewall-bouncer
   ```

3. Kopiere den generierten API-Schlüssel. Er wird in etwa so aussehen:
   ```
   API key for 'firewall-bouncer': 78dfc50ef329a96aexxxxxxxxxxxxxxx
   ```

## 3. API-Schlüssel in die .env-Datei eintragen

1. Öffne deine `.env`-Datei:
   ```bash
   nano .env
   ```

2. Füge die folgende Zeile hinzu, ersetze `<API-SCHLÜSSEL>` mit dem tatsächlichen Schlüssel:
   ```
   BOUNCER_API_KEY=<API-SCHLÜSSEL>
   ```

3. Speichere und schließe die Datei.

## 4. Den Bouncer starten

Starte den Bouncer mit dem folgenden Befehl:
```bash
docker compose up -d crowdsec-firewall-bouncer
```

## 5. Überprüfen, ob alles funktioniert

1. Überprüfe die Logs des Bouncers:
   ```bash
   docker logs crowdsec-firewall-bouncer
   ```
   
   Du solltest Ausgaben wie diese sehen:
   ```
   time="2025-07-18T12:34:56Z" level=info msg="backend.Init() called"
   time="2025-07-18T12:34:56Z" level=info msg="Creating iptables chains"
   time="2025-07-18T12:34:57Z" level=info msg="Starting processing decisions"
   ```

2. Prüfe, ob der Bouncer ordnungsgemäß bei CrowdSec registriert ist:
   ```bash
   docker exec crowdsec cscli bouncers list
   ```

3. Überprüfe, ob iptables-Regeln erstellt wurden:
   ```bash
   docker exec crowdsec-firewall-bouncer iptables -L | grep CROWDSEC
   ```

## 6. Test: Blockierung einer IP

1. Blockiere eine Test-IP (verwende eine IP, die nicht wichtig ist):
   ```bash
   docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 10m --reason "Test blockierung"
   ```

2. Überprüfe, ob die IP blockiert wurde:
   ```bash
   docker exec crowdsec cscli decisions list
   ```

3. Überprüfe, ob die IP in iptables erscheint:
   ```bash
   docker exec crowdsec-firewall-bouncer ipset list crowdsec-blacklists
   ```

## Häufige Probleme und Lösungen

### Problem: "Image nicht gefunden"-Fehler
Lösung: Stelle sicher, dass du das korrekte Image `crowdsecurity/firewall-bouncer` verwendest.

### Problem: Bouncer kann nicht mit CrowdSec kommunizieren
Lösung: 
- Überprüfe, ob der API-Schlüssel korrekt ist
- Prüfe, ob die URL `api_url: http://crowdsec:8080` in der Konfiguration korrekt ist

### Problem: Keine Blockierungen aktiv
Lösung:
- Prüfe die Bouncer-Logs auf Fehler
- Stelle sicher, dass der Bouncer die nötigen Berechtigungen hat (`NET_ADMIN`, `NET_RAW`)
- Verifiziere, dass die iptables-Ketten korrekt konfiguriert sind

### Problem: Firewall-Regeln werden nicht angewendet
Lösung:
- Überprüfe, ob Docker im Host-Netzwerk-Modus läuft (`network_mode: host`)
- Stelle sicher, dass die richtigen Capabilities gesetzt sind
