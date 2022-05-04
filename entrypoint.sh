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

# socat will make the conn appear to come from 127.0.0.1
# ProtonMail Bridge currently expects that.
# It also allows us to bind to the real ports :)
socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &

/srv/protonmail/proton-bridge --cli $@
