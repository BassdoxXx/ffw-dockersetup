# CrowdSec Configuration

This directory contains the configuration files for CrowdSec.

## Changes Made

- Updated docker-compose.yaml to mount the entire ./configs/crowdsec directory to /etc/crowdsec in the container
- This eliminates the need to manually copy acquis.yaml to config/acquis.yaml after updates
- All configuration files should be placed directly in this directory for automatic detection

## Configuration Files

- acquis.yaml: Defines the log sources to monitor
- Additional configuration files will be stored here

## Notes

When updating configurations, simply update the files in this directory and restart CrowdSec:

```bash
docker compose restart crowdsec
```
