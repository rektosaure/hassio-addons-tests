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

# Export config.env so Remaster's shell entrypoint sees the same values as its
# Python configuration loader.
set -a
# shellcheck source=/dev/null
source "${RUNTIME_CONFIG}"
set +a

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
