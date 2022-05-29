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

HEALTHCHECK --timeout=2s CMD nc -z 127.0.0.1 1025 && nc -z 127.0.0.1 1143

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass libsecret-1-0 ca-certificates curl gosu netcat \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sSL https://github.com/krallin/tini/releases/download/v0.19.0/tini-$(dpkg --print-architecture) -o /tini \
    && chmod +x /tini

# Copy bash scripts
COPY gpgparams entrypoint.sh run_protonmail_bridge.sh cli.sh /protonmail/script/
RUN ln -s /protonmail/script/cli.sh /usr/local/bin/cli
# Copy protonmail
COPY --from=build /build/proton-bridge/proton-bridge /usr/local/bin/

VOLUME [ "/protonmail/data" ]

ENTRYPOINT ["/tini", "--", "/protonmail/script/entrypoint.sh"]
