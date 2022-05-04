#!/bin/bash

set -ex

VERSION=`cat VERSION`

# Clone new code
git clone https://github.com/ProtonMail/proton-bridge.git
cd proton-bridge
git checkout v$VERSION

ls /build

# Patch HTTP REST frontend
rm -rf internal/frontend/cli
cp -r /build/http_rest_frontend/cli internal/frontend/cli

# Workaround for 32bit build. More details can be found in:
#   https://github.com/antlr/antlr4/issues/2433#issuecomment-774514106
if [[ $(uname -m) == "armv7l" ]]; then
	find $(go env GOPATH)/pkg/mod/github.com/\!proton\!mail/go-rfc5322*/ -type f -exec sed -i.bak 's/(1<</(int64(1)<</g' {} +
fi

# Build
make build-nogui
