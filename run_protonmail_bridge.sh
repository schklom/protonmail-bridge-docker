#!/bin/bash

set -e

# Generate gpg keys
GNUPG_PATH=/protonmail/data/.gnupg
export GNUPGHOME=${GNUPG_PATH}
if [ ! -d ${GNUPG_PATH} ]; then
    echo "Generateing gpg keys..."
    # set GNUPGHOME to a temp directory as a workaround for
    #
    #   gpg-agent[106]: error binding socket to '/root/.gnupg/S.gpg-agent': File name too long
    #
    # when using docker volume mount
    #
    # ref: https://dev.gnupg.org/T2964
    #
    export GNUPGHOME=/tmp/gnupg
    mkdir ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    gpg --generate-key --batch /protonmail/bin/gpgparams
    pkill gpg-agent
    mv ${GNUPGHOME} ${GNUPG_PATH}
    export GNUPGHOME=${GNUPG_PATH}
fi

# Initialize pass
PASSWORD_STORE=/protonmail/data/.password-store
if [ ! -d ${PASSWORD_STORE} ]; then
    echo "Initializing pass..."
    pass init pass-key
    # Move password store to /protonmail/data
    mv ${HOME}/.password-store ${PASSWORD_STORE}
fi
# Link the password store back to ~/.password-store
# There is no easy way to change the path used by pass
ln -s ${PASSWORD_STORE} ${HOME}/.password-store

# Link config and cache folders to /protonmail/data
PROTON_CONFIG_PATH=/protonmail/data/config
PROTON_CACHE_PATH=/protonmail/data/cache
mkdir -p ${PROTON_CONFIG_PATH}
mkdir -p ${HOME}/.config
ln -s ${PROTON_CONFIG_PATH} ${HOME}/.config/protonmail
mkdir -p ${PROTON_CACHE_PATH}
mkdir ${HOME}/.cache
ln -s ${PROTON_CACHE_PATH} ${HOME}/.cache/protonmail

# Generateing perfs.json
mkdir -p ${PROTON_CONFIG_PATH}/bridge
if [ ${PROTON_SMTP_SECURITY:-STARTTLS} == "SSL" ]; then
    PROTON_SSL_SMTP="true"
else
    PROTON_SSL_SMTP="false"
fi
cat <<EOF > ${PROTON_CONFIG_PATH}/bridge/prefs.json
{
    "allow_proxy": "${PROTON_ALLOW_PROXY:-true}",
    "autoupdate": "false",
    "user_ssl_smtp": "${PROTON_SSL_SMTP}"
}
EOF

# socat will make the conn appear to come from 127.0.0.1
# ProtonMail Bridge currently expects that.
# It also allows us to bind to the real ports :)
socat TCP-LISTEN:${PROTON_SMTP_PORT:=25},fork TCP:127.0.0.1:1025 &
socat TCP-LISTEN:${PROTON_IMAP_PORT:=143},fork TCP:127.0.0.1:1143 &

exec proton-bridge --cli "$@"
