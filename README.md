# Cloudflare Tunnel Deployment mit Docker

Dieses Setup stellt einen Cloudflare Tunnel bereit, über den Dienste auf einem privaten Server (z. B. Vaultwarden, Dashboard, Engelsystem) sicher und ohne offene Ports im Internet erreichbar sind.

## 🔐 Voraussetzungen

- Docker & Docker Compose sind installiert
- Die Domain `ffw-windischletten.de` ist bei Cloudflare eingebunden
- Ein Cloudflare-Tunnel ist erstellt und ein Token wurde generiert
- Externes Docker-Netzwerk `core_net` ist vorhanden (für App-Kommunikation)

## 📁 Projektstruktur
.
├── docker-compose.cloudflared.yml
├── .env # enthält das Cloudflare Tunnel Token
└── .gitignore

## ⚙️ .env-Datei (nicht ins Repo!)

Erstelle eine Datei `.env` im Projektverzeichnis mit folgendem Inhalt:

