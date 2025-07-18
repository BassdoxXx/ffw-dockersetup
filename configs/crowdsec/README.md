# CrowdSec Configuration

This directory is the parent directory for CrowdSec configurations.

## Directory Structure

- `config/`: Contains all CrowdSec configuration files that get mounted to /etc/crowdsec
- `data/`: Contains CrowdSec data files

## Setup Instructions

### Log File Permissions

CrowdSec needs read access to system log files. To grant this access:

1. Create a `logreader` group on the host system:
```bash
sudo groupadd logreader
```

2. Find the GID of the group:
```bash
getent group logreader
# Example output: logreader:x:1001:
```

3. Make sure the GID in docker-compose.yaml matches:
```yaml
crowdsec:
  # ... other configuration ...
  group_add:
    - "1001"  # Replace with the actual GID of the logreader group
```

4. Give the logreader group read access to log files:
```bash
# Set group ownership
sudo find /var/log -type f -exec chgrp logreader {} \; 2>/dev/null || true
sudo find /var/log -type d -exec chgrp logreader {} \; 2>/dev/null || true

# Set read permissions
sudo find /var/log -type f -exec chmod g+r {} \; 2>/dev/null || true
sudo find /var/log -type d -exec chmod g+rx {} \; 2>/dev/null || true
```

5. Restart CrowdSec:
```bash
docker compose restart crowdsec
```

## Important Note

All configuration files should be placed in the `config/` directory, including:
- `config/acquis.yaml`: Defines the log sources to monitor
- Other CrowdSec configuration files

The current setup mounts `./configs/crowdsec/config` to `/etc/crowdsec` in the container

## Monitoring Log Files

The following log files are currently monitored:
- System logs (fail2ban, alternatives, dpkg)
- System journal files
- Nginx logs (when present)
- Docker container logs

To check which logs are being monitored:
```bash
docker exec crowdsec cscli metrics
```

## Notes

When updating configurations, simply update the files in this directory and restart CrowdSec:

```bash
docker compose restart crowdsec
```
