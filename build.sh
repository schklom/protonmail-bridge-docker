#!/bin/bash

set -ex

# Clone new code
git clone https://github.com/ProtonMail/proton-bridge.git
cd proton-bridge
git checkout ${BRIDGE_VERSION}

# Patch HTTP REST frontend
rm -rf internal/frontend/cli
cp -r /build/http_rest_frontend/cli internal/frontend/

# Build
if ! make build-nogui ; then
	# If build fails it's probably because it is a 32bit
	# system and there was a overflow error on the parser
	# This is a workaround for this problem found at:
	#   https://github.com/antlr/antlr4/issues/2433#issuecomment-774514106
	find $(go env GOPATH)/pkg/mod/github.com/\!proton\!mail/go-rfc5322*/ -type f -exec sed -i.bak 's/(1<</(int64(1)<</g' {} +

	# Try again after implementing the workaround
	make build-nogui
fi
