#!/usr/bin/env bashio
# shellcheck shell=bash
set -eo pipefail

CONFIG_FILE="/config/config.env"
if bashio::config.has_value 'CONFIG_LOCATION'; then
    CONFIG_FILE="$(bashio::config 'CONFIG_LOCATION')"
fi
CONFIG_DIR="$(dirname "${CONFIG_FILE}")"
RUNTIME_CONFIG="/data/config.env"

mkdir -p "${CONFIG_DIR}" /data

if [ ! -f "${CONFIG_FILE}" ]; then
    install -m 0600 /templates/config.env "${CONFIG_FILE}"
    bashio::log.warning \
        "Created ${CONFIG_FILE}. Add account credentials there and restart the add-on if automatic login is required."
else
    bashio::log.info "Using configuration from ${CONFIG_FILE}"
fi

# Remaster reads /fgc/data/config.env. /fgc/data is linked to Home Assistant's
# persistent /data volume by the Dockerfile.
install -m 0600 "${CONFIG_FILE}" "${RUNTIME_CONFIG}"
sed -i 's/\r$//' "${RUNTIME_CONFIG}"

# Keep explicit env_vars as final overrides after loading config.env.
mapfile -t ENV_VAR_NAMES < <(jq -r '.env_vars[]? | .name // empty' /data/options.json)
declare -A ENV_VAR_VALUES=()
for name in "${ENV_VAR_NAMES[@]}"; do
    if [[ -v "${name}" ]]; then
        ENV_VAR_VALUES["${name}"]="${!name}"
    fi
done

# Parse config.env with Remaster's python-dotenv dependency instead of sourcing
# user-controlled dotenv content as shell code.
DOTENV_DATA="$(mktemp)"
python3 - "${RUNTIME_CONFIG}" > "${DOTENV_DATA}" <<'PY'
import re
import sys

from dotenv import dotenv_values

for key, value in dotenv_values(sys.argv[1]).items():
    if value is None or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key) is None:
        continue
    sys.stdout.buffer.write(key.encode())
    sys.stdout.buffer.write(b"\0")
    sys.stdout.buffer.write(value.encode())
    sys.stdout.buffer.write(b"\0")
PY

while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    export "${key}=${value}"
done < "${DOTENV_DATA}"
rm -f "${DOTENV_DATA}"

for name in "${ENV_VAR_NAMES[@]}"; do
    if [[ -v 'ENV_VAR_VALUES[$name]' ]]; then
        export "${name}=${ENV_VAR_VALUES[$name]}"
    fi
done

# noVNC and VNC are fixed by the add-on port mapping.
export NOVNC_PORT="7080"
export VNC_PORT="5900"

APP_COMMAND=(python3 /fgc/main.py)
RUN_ONCE="true"
if bashio::config.has_value 'RUN_ONCE' && ! bashio::config.true 'RUN_ONCE'; then
    RUN_ONCE="false"
fi

if [ "${RUN_ONCE}" = "true" ]; then
    APP_COMMAND+=(--once)
    bashio::log.info "Starting a single claiming run"

    set +e
    /usr/local/bin/docker-entrypoint.sh "${APP_COMMAND[@]}"
    exit_code=$?
    set -e

    if [ "${exit_code}" -ne 0 ]; then
        bashio::log.error "Free Games Claimer exited with status ${exit_code}"
    else
        bashio::log.info "Claiming run completed"
    fi

    bashio::log.info "Stopping the add-on"
    sleep 2
    bashio::addon.stop
    exit "${exit_code}"
fi

bashio::log.info "Starting the built-in scheduler"
exec /usr/local/bin/docker-entrypoint.sh "${APP_COMMAND[@]}"
