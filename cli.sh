#!/bin/bash

set -e

URL_BASE=http://127.0.0.1:${PROTON_MANAGEMENT_PORT:-1080}

print_help() {
    echo "Available commands:"
    echo " login:            Calls up the login procedure to add or connect accounts."
    echo " delete <account>: Remove the account from keychain. You can use index or account name as the parameter."
    echo " list:             Print list of your accounts."
    echo " info <account>:   Print account configuration. You can use index or account name as the parameter."
    echo " help:             Print help messages."
    echo " exit:             Exit the CLI"
}

account_list() {
    curl ${URL_BASE}/accounts
}

account_login() {
    read -p "Username: " USERNAME
    read -sp "Password: " PASSWORD
    echo
    read -p "2FA Code (leave empty if not set): " TWO_FACTOR
    read -p "Mailbox Password (leave empty if not set): " MAILBOX_PASSWORD
    read -p "Address Mode (combined / split): " ADDRESS_MODE

    curl ${URL_BASE}/accounts -XPUT \
        --data-urlencode "username=${USERNAME}" \
        --data-urlencode "password=${PASSWORD}" \
        --data-urlencode "two-factor=${TWO_FACTOR}" \
        --data-urlencode "mailbox-password=${MAILBOX_PASSWORD}" \
        --data-urlencode "address-mode=${ADDRESS_MODE}"
}

account_delete() {
    if [[ -z $1 ]]; then
        echo "Error: delete requires one parameter, which is the index or account name."
    else
        read -p "Are you sure you want to delete account $1? " REPLY
        if [[ $REPLY =~ ^[Yy] ]]; then
            curl ${URL_BASE}/accounts/$1 -XDELETE
        else
            echo "Abort"
        fi
    fi
}

account_info() {
    if [[ -z $1 ]]; then
        echo "Error: info requires one parameter, which is the index or account name."
    else
        curl ${URL_BASE}/accounts/$1
    fi
}

echo "CLI to interacte with Proton Bridge HTTP REST interface"
print_help
while true; do
    echo
    read -p ">> " COMMAND ARG
    case "$COMMAND" in
        login)
            account_login;;
        delete)
            account_delete $ARG;;
        list)
            account_list;;
        info)
            account_info $ARG;;
        help)
            print_help;;
        exit)
            exit 0;;
        *)
            echo "Invalid command"
    esac
done
