#!/bin/bash
# Container entrypoint: the only code that runs as root.
# Applies the egress firewall, then hands off to the container command.
# Fails closed: if the firewall cannot be applied, the container does not start.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "entrypoint: must start as root to apply the firewall (set containerUser: root)" >&2
    exit 1
fi

/usr/local/bin/init-firewall.sh

exec "$@"
