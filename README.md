# ffw-dockersetup 🚒

Docker-basierte Infrastruktur für die Feuerwehr Windischletten.  
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

## 📁 Ordnerstruktur

```
.
├── docker-compose.yaml      # Zentrale Definition aller Dienste
├── .env                     # Vertrauliche Umgebungsvariablen (nicht in Git!)
├── update.sh                # Pull + Restart der Container
├── configs/                 # Konfigurationen, die versioniert werden
│   ├── homepage/            # YAML-Dateien für das Homepage-Dashboard
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

## 📅 Geplante Erweiterungen

- Engelsystem als eigener Container
- SMTP-Benachrichtigung für Dienste
- Einladungssystem für Feiern
- 

## 🧯 Maintainer

Martin Griebel  
[https://martingriebel.de](https://martingriebel.de)