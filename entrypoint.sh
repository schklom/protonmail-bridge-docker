#!/bin/bash

set -e

echo "Welcome to ProtonMail Bridge Docker 2.0. This version comes with plently of"
echo "improvements. This version is not compatible with old configs and data volumes."
echo "If you are coming from the old version, please clean up your volumes and set up"
echo "everything from scratch. For more information about the new version, check"
echo "https://github.com/shenxn/protonmail-bridge-docker"
echo

if [ -d /root/.config/protonmail ]; then
    echo "Volume mount at `/root` for old version found. Please change your mount path to `/protonmail/data`."
    echo "See https://github.com/shenxn/protonmail-bridge-docker for detailed migration guide."
    echo "Exit in 30 seconds..."
    sleep 30
    exit 1
fi

groupadd -g ${PROTON_GID:-1001} proton
useradd -g proton -u ${PROTON_UID:-1001} -m proton
chown proton:proton /protonmail/data

# Migrate old version data
if [ -d /protonmail/data/.config/protonmail ]; then
    echo "Migrating legacy data. Note that this operation is irreversible so it is impossible"
    echo "to go back to the old version without clearing the volume."
    echo

    mv /protonmail/data/.config/protonmail /protonmail/data/config
    rm -rf /protonmail/data/.config
    mv /protonmail/data/.cache/protonmail /protonmail/data/cache
    rm -rf /protonmail/data/.cache
    chown proton:proton -R /protonmail/data
fi

exec gosu proton:proton run_protonmail_bridge.sh "$@"
