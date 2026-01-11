#!/usr/bin/env bash
# Collect and print basic system information

set -euo pipefail

. "$(dirname "$0")/utils.sh" || exit 1

log "Collecting system information..."

uname -a

if command -v lsb_release >/dev/null 2>&1; then
  lsb_release -a || true
fi

cat /etc/os-release || true

echo
log "Kernel and CPU:"
cat /proc/cpuinfo | grep -E "model name|vendor_id|cpu MHz" | head -n 10 || true

echo
log "Memory:"
free -h || true

echo
log "Disk usage:"
lsblk -f || true

# Optional more details
if command -v df >/dev/null 2>&1; then
  df -h --output=source,fstype,size,used,avail,pcent,target | sed '1d' | sed -E 's/^\s+//'
fi

log "System info collection complete."
