# ffw-dockersetup 🚒

Docker-basierte Infrastruktur für die Feuerwehr W## 🛡️ Sicherheit mit CrowdSec

Das Setup beinhaltet [CrowdSec](https://crowdsec.net/) zur Angriffserkennung:

1. **CrowdSec Engine** (Docker): Überwacht Logs und erkennt Angriffsmuster

```bash
# Anzeige aller erkannten Bedrohungen
docker exec crowdsec cscli alerts list

# Anzeige aller Blockierungen
docker exec crowdsec cscli decisions list
```
Ziel ist ein wartbares, sicheres und zentrales Setup für alle internen Dienste.

## 📦 Enthaltene Services

| Dienst        | Beschreibung                            | URL                                 |
|---------------|-----------------------------------------|--------------------------------------|
| Vaultwarden   | Passwortmanager für die Feuerwehr       | `https://pw.ffw-windischletten.de`   |
| Homepage      | Dashboard & Serviceübersicht            | `https://home.ffw-windischletten.de` |
| Engelsystem   | Helfer- und Schichtverwaltung (folgt)   | `https://engelsystem.ffw-windischletten.de` |
| Watchtower    | Automatische Container-Updates          | –                                    |
| PostgreSQL    | Zentrale Datenbank für Dienste          | intern                               |
| Cloudflared   | Tunneling via Cloudflare ohne Port-Forwarding | –                             |
| CrowdSec      | Sicherheits-Engine zur Angriffserkennung und -abwehr | –                      |

## 📁 Ordnerstruktur

```
.
├── docker-compose.yaml      # Zentrale Definition aller Dienste
├── .env                     # Vertrauliche Umgebungsvariablen (nicht in Git!)
├── update.sh                # Pull + Restart der Container
├── remove-bouncer.sh        # Script zum Entfernen des CrowdSec Bouncers
├── configs/                 # Konfigurationen, die versioniert werden
│   ├── homepage/            # YAML-Dateien für das Homepage-Dashboard
│   ├── crowdsec/            # CrowdSec Konfigurationen (acquis.yaml, etc.)
│   └── watchtower/          # (Optional) Watchtower-Konfiguration
├── data/                    # Persistente Volumes für Dienste (nicht versionieren)
│   ├── db/                  # PostgreSQL-Daten
│   ├── homepage/            # Laufzeitdaten Homepage
│   └── vaultwarden/         # Vaultwarden Daten
```

## 🚀 Deployment

1. `.env` Datei erstellen und sensible Werte eintragen (siehe `.env.example`)
2. Docker Compose starten:

```bash
docker compose up -d
```

3. Logs prüfen (optional):

```bash
docker logs -f homepage
```

## 🔧 Wichtige Variablen (.env)

```env
POSTGRES_USER=...
POSTGRES_PASSWORD=...
CF_TUNNEL_TOKEN=...
```

Diese Datei **niemals ins Git pushen!**

## 📊 Monitoring (Docker-Integration)

Die `homepage` App zeigt für jeden konfigurierten Dienst:

- CPU
- RAM
- Netzwerk
- Verfügbarkeit via Ping / SiteMonitor

Konfigurierbar über `configs/homepage/services.yaml`.

## � Sicherheit mit CrowdSec

Das Setup beinhaltet [CrowdSec](https://crowdsec.net/) zur Angriffserkennung und -abwehr:

1. **CrowdSec Engine** (Docker): Überwacht Logs und erkennt Angriffsmuster
2. **Firewall Bouncer** (nativ): Blockiert erkannte Angreifer auf Firewall-Ebene

Siehe `setup-native-bouncer.md` für die Installation des nativen Bouncers.

```bash
# Anzeige aller erkannten Bedrohungen
docker exec crowdsec cscli alerts list

# Anzeige aller Blockierungen
docker exec crowdsec cscli decisions list
```

## �📅 Geplante Erweiterungen

- Engelsystem als eigener Container
- SMTP-Benachrichtigung für Dienste
- Einladungssystem für Feiern
- CrowdSec Dashboard für Angriffserkennung

## 🧯 Maintainer

Martin Griebel  
[https://martingriebel.de](https://martingriebel.de)