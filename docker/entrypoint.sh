#!/bin/bash

set -e

# Generate gpg keys
if [ ! -f ${HOME}/.gnupg ]; then
    echo "Generateing gpg keys..."
    # set GNUPGHOME as a workaround for
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
    gpg --generate-key --batch /srv/protonmail/gpgparams
    pkill gpg-agent
    mv ${GNUPGHOME} ${HOME}/.gnupg
    export GNUPGHOME=""
fi

# Initialize pass
if [ ! -f ${HOME}/.password-store/.gpg-id ]; then
    echo "Initializing pass"
    pass init pass-key
fi

# Login
if [ ! -f ${HOME}/.logged-in ]; then
    if [[ -n ${PROTONMAIL_USERNAME} && -n ${PROTONMAIL_PASSWORD} ]]; then
        echo "Logging in"
        auto-login.exp $@
        echo "" > ${HOME}/.logged-in
    else
        # Wait for manual login
        echo "=============================================================================="
        echo "PROTONMAIL_USERNAME or PROTONMAIL_PASSWORD is not set. Will not do auto login."
        echo "Run docker exec -it protonmail login.sh to login manually."
        echo "Waiting for manual login..."
        while [ ! -f ${HOME}/.logged-in ]; do
            sleep 5
        done
    fi
fi

echo "Logged in flag detected. Starting protonmail bridge"


# socat will make the conn appear to come from 127.0.0.1
# ProtonMail Bridge currently expects that.
# It also allows us to bind to the real ports :)
socat TCP-LISTEN:2025,fork TCP:127.0.0.1:1025 &
socat TCP-LISTEN:2143,fork TCP:127.0.0.1:1143 &

# Start protonmail
# Fake a terminal, so it does not quit because of EOF...
rm -f faketty
mkfifo faketty
cat faketty | proton-bridge --cli $@
