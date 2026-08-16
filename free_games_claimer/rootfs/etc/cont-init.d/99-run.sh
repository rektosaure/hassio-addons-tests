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

# Recover from an old add-on bug that could create config.env as a directory.
if [ -d "${CONFIG_FILE}" ]; then
    bashio::log.warning "Found a directory at ${CONFIG_FILE}; replacing it with a configuration file"
    rm -rf "${CONFIG_FILE}"
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    install -m 0600 /templates/config.env "${CONFIG_FILE}"
    bashio::log.warning \
        "Created ${CONFIG_FILE}. Add account credentials there and restart the add-on if automatic login is required."
else
    bashio::log.info "Using configuration from ${CONFIG_FILE}"
fi

# The remaster reads /fgc/data/config.env. /fgc/data is linked to Home
# Assistant's persistent /data volume by the Dockerfile.
install -m 0600 "${CONFIG_FILE}" "${RUNTIME_CONFIG}"
sed -i 's/\r$//' "${RUNTIME_CONFIG}"

# Export values needed by the VNC entrypoint as well as by the Python app.
set -a
# shellcheck source=/dev/null
source "${RUNTIME_CONFIG}"
set +a

# Remaster v1.5 and Home Assistant both use noVNC on port 7080.
if [ -n "${NOVNC_PORT:-}" ] && [ "${NOVNC_PORT}" != "7080" ]; then
    bashio::log.warning "NOVNC_PORT=${NOVNC_PORT} is not supported by the add-on; using 7080"
fi
export NOVNC_PORT="7080"
export VNC_PORT="5900"

# Absolute paths from the former image pointed to its Firefox profile. The
# replacement uses Chromium profiles and must start with a separate directory.
if [ "${BROWSER_DIR:-}" = "/data/data/browser" ]; then
    bashio::log.warning "Remapping legacy Firefox BROWSER_DIR to the remaster Chromium profile directory"
    export BROWSER_DIR="data/browser"
fi
if [ "${SCREENSHOTS_DIR:-}" = "/data/data/screenshots" ]; then
    export SCREENSHOTS_DIR="/fgc/data/screenshots"
fi

# A non-empty STORES add-on option takes priority. Otherwise keep a STORES value
# from config.env, then fall back to the add-on's historical Epic/Prime/GOG set.
STORES_OPTION=""
if bashio::config.has_value 'STORES'; then
    STORES_OPTION="$(bashio::config 'STORES')"
fi
if [ -n "${STORES_OPTION}" ]; then
    export STORES="${STORES_OPTION}"
elif [ -z "${STORES:-}" ]; then
    export STORES="epic,prime,gog"
fi

bashio::log.info "Enabled stores: ${STORES}"

# Import claim history from vogler/free-games-claimer once. Legacy files and
# browser data are retained under /data/data for rollback and manual recovery.
/usr/local/bin/migrate_vogler_data.py

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
