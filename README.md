# ffw-dockersetup 🚒

Docker-basierte Infrastruktur für eine Organisationsplattform ## 🛡️ Sicherheit mit CrowdSec

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
| Vaultwarden   | Passwortmanager für die Feuerwehr       | `https://pw.example.org`   |
| Homepage      | Dashboard & Serviceübersicht            | `https://home.example.org` |
| Engelsystem   | Helfer- und Schichtverwaltung           | `https://helfer.example.org` |
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
├── app/                     # Quellcode für Container-Builds
│   └── engelsystem/         # Engelsystem Quellcode (geklontes Repository)
├── configs/                 # Konfigurationen, die versioniert werden
│   ├── homepage/            # YAML-Dateien für das Homepage-Dashboard
│   ├── crowdsec/            # CrowdSec Konfigurationen (acquis.yaml, etc.)
│   └── watchtower/          # (Optional) Watchtower-Konfiguration
├── data/                    # Persistente Volumes für Dienste (nicht versionieren)
│   ├── db/                  # PostgreSQL-Daten
│   ├── engelsystem/         # Engelsystem Daten und Konfiguration
│   ├── homepage/            # Laufzeitdaten Homepage
│   ├── simple_invites/      # Einladungssystem Daten
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

## 🧩 Engelsystem Setup

Das Engelsystem ist ein Helferverwaltungssystem, das für die Organisation von Schichten und Diensten verwendet wird.

### 1. Vorbereitung

```bash
# Repository klonen und Verzeichnisse vorbereiten
sudo chown -R $USER:$USER ./app
mkdir -p app/engelsystem
git clone https://github.com/engelsystem/engelsystem.git app/engelsystem

# Verzeichnisse für persistente Daten erstellen
mkdir -p data/engelsystem/{config,storage,resources,db}
chmod -R 775 data/engelsystem
```

### 2. Docker Compose Konfiguration

Die folgenden Dienste müssen in der `docker-compose.yaml` enthalten sein:

```yaml
  engelsystem:
    build: 
      context: ./app/engelsystem
      dockerfile: docker/Dockerfile
    container_name: engelsystem
    restart: unless-stopped
    environment:
      MYSQL_TYPE: mariadb
      MYSQL_HOST: engelsystem_db
      MYSQL_USER: engelsystem
      MYSQL_PASSWORD: engelsystem
      MYSQL_DATABASE: engelsystem
      ENVIRONMENT: production
      APP_URL: https://helfer.example.org
    volumes:
      - ./data/engelsystem/config:/var/www/html/config
      - ./data/engelsystem/storage:/var/www/html/storage
      - ./data/engelsystem/resources:/var/www/html/resources
    networks:
      - core_net
    depends_on:
      - engelsystem_db
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
      
  engelsystem_db:
    image: mariadb:10.7
    container_name: engelsystem_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: engelsystem
      MYSQL_USER: engelsystem
      MYSQL_PASSWORD: engelsystem
      MYSQL_RANDOM_ROOT_PASSWORD: "1"
      MYSQL_INITDB_SKIP_TZINFO: "yes"
    volumes:
      - ./data/engelsystem/db:/var/lib/mysql
    networks:
      - core_net
```

### 3. Container starten und Datenbank migrieren

```bash
# Container starten
docker compose up -d engelsystem_db
# 10 Sekunden warten, bis die Datenbank hochgefahren ist
sleep 10
docker compose up -d engelsystem

# Datenbank migrieren
docker compose exec engelsystem bin/migrate
```

Nach Abschluss dieser Schritte ist das Engelsystem unter `https://helfer.example.org` erreichbar. Der initiale Admin-Benutzer hat den Benutzernamen `admin` mit dem Passwort `asdfasdf`. **Wichtig:** Ändere das Passwort sofort nach der ersten Anmeldung!

## 📅 Geplante Erweiterungen

- SMTP-Benachrichtigung für Dienste
- CrowdSec Dashboard für Angriffserkennung/Blockierung

## 🧯 Maintainer

Martin Griebel  
[https://martingriebel.de](https://martingriebel.de)