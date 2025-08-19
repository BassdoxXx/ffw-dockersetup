This directory is a Git-managed replacement for /etc/crowdsec.
Only the files present here will be visible inside the crowdsec container due to the bind mount.

Included files:
- config.yaml : Main CrowdSec configuration
- acquis.yaml : Log acquisition sources (traefik access logs)
- profiles.yaml : Decision profiles
- appsec/ : (currently empty, placeholder for future AppSec listener configuration)

To add additional hub assets (parsers, scenarios, etc.) you must either:
1. Let the container download them via COLLECTIONS environment variable (preferred), or
2. Commit the resulting directories (collections/, parsers/, scenarios/, postoverflows/, patterns/, contexts/, hub/) after an initial run in a temporary container.

If you add hub-managed directories here, remove them from COLLECTIONS env to avoid repeated re-installs.
