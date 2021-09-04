FROM golang:1.16 AS build

# Install dependencies
RUN apt-get update && apt-get install -y libsecret-1-dev

# Build
WORKDIR /build/
COPY VERSION /build/

RUN VERSION=$(cat VERSION) && \
    curl -L https://github.com/ProtonMail/proton-bridge/archive/refs/tags/${VERSION}.tar.gz \
        | tar zx --strip-component 1 && \
    make build-nogui

FROM ubuntu:bionic
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        expect socat pass libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy protonmail
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

# Copy bash scripts
COPY gpgparams entrypoint.sh login.exp /protonmail/

RUN chmod +x /protonmail/login.exp

# Add a user 'protonmail' with UID 8535
RUN useradd -u 8535 -d /home/protonmail protonmail \
    && mkdir -p /home/protonmail \
    && chown protonmail: /home/protonmail
# change to non-privileged user for extra security
USER protonmail

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
