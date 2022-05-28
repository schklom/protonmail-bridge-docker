#!/bin/bash

set -e

echo "Welcome to ProtonMail Bridge Docker 2.0. This version comes with plently of"
echo "improvements. This version is not compatible with old configs and data volumes."
echo "If you are coming from the old version, please clean up your volumes and set up"
echo "everything from scratch. For more information about the new version, check"
echo "https://github.com/shenxn/protonmail-bridge-docker"
echo

groupadd -g ${PROTON_GID:-1001} proton
useradd -g proton -u ${PROTON_UID:-1001} -m proton
chown proton:proton -R /protonmail/data

exec gosu proton:proton run_protonmail_bridge.sh "$@"
