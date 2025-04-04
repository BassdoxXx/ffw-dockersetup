# ffw-dockersetup
 Beschreibt alle Dienste im FFW Netz


# NPM + Cloudflared Setup

Dieses Repository enthält ein `docker-compose.yaml`, um **Nginx Proxy Manager** und **Cloudflared** gemeinsam in einem Container-Setup zu betreiben.

## Nutzung

1. `.env`-Datei erstellen:

```bash
cp .env.example .env
nano .env
```

2. Docker-Container starten

docker compose up -d


3. NPM ist erreichbar unter:

http://[SERVER-IP]:81 (Webinterface)

http://[SERVER-IP] / https://[SERVER-IP] für Weiterleitungen

4. Cloudflared verbindet automatisch den Tunnel zu Cloudflare.

