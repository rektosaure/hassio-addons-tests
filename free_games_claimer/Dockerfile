#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#=== Home Assistant Add-on ===#

ARG BUILD_FROM="ghcr.io/p-adamiec/free-games-claimer-remaster:v1.5"
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ARG UPSTREAM_REPOSITORY="P-Adamiec/Free-Games-Claimer-Remaster"
ARG UPSTREAM_VERSION="v1.5"

ENV S6_CMD_WAIT_FOR_SERVICES="1" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_SERVICES_GRACETIME="0"

# Keep Remaster's persistent data in Home Assistant's /data volume.
RUN rm -rf /fgc/data \
    && ln -s /data /fgc/data

# Add Home Assistant integration files.
COPY rootfs/ /
RUN find /etc/cont-init.d -type f -name "*.sh" -exec chmod 0755 {} +

# Use the shared AlexBelgium modules. 00-global_var.sh provides the standard
# env_vars option declared by this add-on.
ARG TEMPLATE_BASE_URL="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates"
ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh"
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_automodules.sh "${TEMPLATE_BASE_URL}/ha_automodules.sh" \
    && chmod 0755 /ha_automodules.sh \
    && /ha_automodules.sh "${MODULES}" \
    && rm /ha_automodules.sh

# Run the standard automatic package and Bashio installer.
ENV PACKAGES=""
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_autoapps.sh "${TEMPLATE_BASE_URL}/ha_autoapps.sh" \
    && chmod 0755 /ha_autoapps.sh \
    && /ha_autoapps.sh "${PACKAGES}" \
    && rm /ha_autoapps.sh

# Add the standard AlexBelgium entrypoint and standalone bashio compatibility.
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_entrypoint.sh "${TEMPLATE_BASE_URL}/ha_entrypoint.sh" \
    && curl -fsSL --retry 3 --retry-delay 2 \
        -o /usr/local/lib/bashio-standalone.sh "${TEMPLATE_BASE_URL}/bashio-standalone.sh" \
    && chmod 0755 /ha_entrypoint.sh /usr/local/lib/bashio-standalone.sh

EXPOSE 5900 7080
ENTRYPOINT ["/usr/bin/env"]
CMD ["/ha_entrypoint.sh"]

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.url="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/master/free_games_claimer/README.md" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}" \
    io.hass.upstream="https://github.com/${UPSTREAM_REPOSITORY}/releases/tag/${UPSTREAM_VERSION}"
