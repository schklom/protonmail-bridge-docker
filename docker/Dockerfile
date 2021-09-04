FROM golang:1.16 AS build

# Install dependencies
RUN apt-get update && apt-get install -y libsecret-1-dev

ARG PROTONMAIL_BRIDGE_VERSION

# Build
WORKDIR /build/
RUN curl -L https://github.com/ProtonMail/proton-bridge/archive/refs/tags/${PROTONMAIL_BRIDGE_VERSION}.tar.gz \
        | tar zx --strip-component 1
RUN make build-nogui

FROM ubuntu:bionic
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        expect socat pass libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/srv/protonmail:$PATH"

# Copy protonmail
COPY --from=build /build/proton-bridge /srv/protonmail/

# Copy bash scripts
COPY gpgparams entrypoint.sh auto-login.exp login.sh /srv/protonmail/

# Create use and group for protonmail
RUN groupadd --gid 8535 protonmail \
    && useradd --uid 8535 --gid 8535 --home-dir /protonmail protonmail \
    && mkdir /protonmail \
    && chown protonmail:protonmail /protonmail
USER protonmail
WORKDIR /protonmail

ENTRYPOINT ["bash", "/srv/protonmail/entrypoint.sh"]
