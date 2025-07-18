# CrowdSec Configuration

This directory is the parent directory for CrowdSec configurations.

## Directory Structure

- `config/`: Contains all CrowdSec configuration files that get mounted to /etc/crowdsec
- `data/`: Contains CrowdSec data files

## Important Note

All configuration files should be placed in the `config/` directory, including:
- `config/acquis.yaml`: Defines the log sources to monitor
- Other CrowdSec configuration files

The current setup mounts `./configs/crowdsec/config` to `/etc/crowdsec` in the container

## Notes

When updating configurations, simply update the files in this directory and restart CrowdSec:

```bash
docker compose restart crowdsec
```
