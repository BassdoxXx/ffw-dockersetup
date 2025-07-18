#!/bin/bash
#
# Cleanup script for CrowdSec Firewall Bouncer
#
# This script completely removes the bouncer and its configurations
#

set -e

echo "============================================================"
echo "CrowdSec Firewall Bouncer - Complete Removal"
echo "============================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root user (sudo)!"
  exit 1
fi

echo "Step 1: Stopping and disabling services..."
systemctl stop crowdsec-firewall-bouncer || true
systemctl disable crowdsec-firewall-bouncer || true

echo "Step 2: Removing packages..."
apt remove --purge -y crowdsec-firewall-bouncer-iptables crowdsec-firewall-bouncer-nftables || true

echo "Step 3: Removing configuration files..."
rm -rf /etc/crowdsec/bouncers
rm -f /tmp/bouncer_output.txt

echo "Step 4: Removing from CrowdSec..."
docker exec crowdsec cscli bouncers delete cs-firewall-bouncer || true

echo "Step 5: Removing ipsets..."
ipset destroy crowdsec-blacklists || true
ipset destroy crowdsec6-blacklists || true

echo "Step 6: Cleaning up firewall rules..."
# Try to find and remove any iptables rules related to CrowdSec
iptables -S | grep -i "crowdsec" | while read -r rule; do
  chain=$(echo "$rule" | awk '{print $2}')
  if [[ "$rule" == "-A"* ]]; then
    # Remove the -A prefix and reconstruct as a delete command
    delete_rule=$(echo "$rule" | sed 's/^-A/-D/')
    echo "Removing rule: $delete_rule"
    iptables $delete_rule || true
  fi
done

# Try to remove chains if they exist
for chain in CROWDSEC_CHAIN CROWDSEC_LOG; do
  if iptables -L "$chain" >/dev/null 2>&1; then
    # Flush chain
    iptables -F "$chain" || true
    # Unlink from other chains
    iptables -D INPUT -j "$chain" 2>/dev/null || true
    iptables -D FORWARD -j "$chain" 2>/dev/null || true
    iptables -D OUTPUT -j "$chain" 2>/dev/null || true
    # Delete chain
    iptables -X "$chain" || true
    echo "Removed chain: $chain"
  fi
done

echo "============================================================"
echo "Removal complete!"
echo "============================================================"
echo ""
echo "All CrowdSec Firewall Bouncer components have been removed."
echo "You may need to restart your system to ensure all changes take effect."
echo ""
