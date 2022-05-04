FROM golang:1.15 AS build

# Install dependencies
RUN apt-get update && apt-get install -y libsecret-1-dev

ARG BRIDGE_VERSION

# Build
WORKDIR /build/
COPY build.sh /build/
COPY http_rest_frontend /build/http_rest_frontend
RUN bash build.sh

FROM ubuntu:bionic
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass libsecret-1-0 ca-certificates dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /srv/protonmail/

# Copy protonmail
COPY --from=build /build/proton-bridge/proton-bridge /srv/protonmail/

ENTRYPOINT ["bash", "/srv/protonmail/entrypoint.sh"]
