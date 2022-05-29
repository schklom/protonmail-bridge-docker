# ProtonMail IMAP/SMTP Bridge Docker Container

![version badge](https://img.shields.io/docker/v/shenxn/protonmail-bridge)
![image size badge](https://img.shields.io/docker/image-size/shenxn/protonmail-bridge/build)
![docker pulls badge](https://img.shields.io/docker/pulls/shenxn/protonmail-bridge)
![deb badge](https://github.com/shenxn/protonmail-bridge-docker/workflows/pack%20from%20deb/badge.svg)
![build badge](https://github.com/shenxn/protonmail-bridge-docker/workflows/build%20from%20source/badge.svg)

This is an unofficial Docker container of the [ProtonMail Bridge](https://protonmail.com/bridge/). Some of the scripts are based on [Hendrik Meyer's work](https://gitlab.com/T4cC0re/protonmail-bridge-docker).

Docker Hub: [https://hub.docker.com/r/shenxn/protonmail-bridge](https://hub.docker.com/r/shenxn/protonmail-bridge)

GitHub: [https://github.com/shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker)

## ProtonMail Bridge Docker 2.0 Announcement

ProtonMail Bridge Docker 2.0 uses a completely different approach that makes the whole container much easier to use. First of all, it now supports setting up with environmental variables only. No longer messing with terminal commands. Secondly, it now provides a easy way to interact with the bridge, include getting account information, adding, and removing accounts, all after the first initialization. This version is now in beta. Feel free to test it by using the `beta` tag (`shenxn/protonmail-bridge:beta`).

### Environmental Variables

name | default | description
 -- | -- | --
`PROTON_USERNAME` | | Username of your Proton account.
`PROTON_PASSWORD` | | Password of your Proton account.
`PROTON_2FA` | | Two-factor authentication code of your Proton account. Only needed if you have two factor authentication enabled.
`PROTON_MAILBOX_PASSWORD` | | Mailbox password of your Proton account. Only needed if you have two-password mode enabled.
`PROTON_PRINT_ACCOUNT_INFO` | `true` | Whether to print the local connection information (username, password, ports, security, etc.) on successful auto logins. Set to `false` to turn it off.
`PROTON_IMAP_PORT` | `25` | IMAP port of the bridge.
`PROTON_SMTP_PORT` | `143` | SMTP port of the bridge.
`PROTON_SMTP_SECURITY` | `STARTTLS` | Connection security of SMTP. Can be set to `STARTTLS` or `SSL`.
`PROTON_MANAGEMENT_PORT` | `1080` | Port of the management HTTP server.
`PROTON_ALLOW_PROXY` | `true` | Allow or disallow the Bridge client to securely connect to Proton via a third party when it is being blocked.
`PROTON_UID` | `1001` | UID of the user to run the bridge.
`PROTON_GID` | `1001` | GID of the group to run the bridge.

### Data Volume

All data are stored under `/protonmail/data`.

### Auto Login

2.0 comes with auto login, a highly demanded feature. By set `PROTON_USERNAME`, `PROTON_PASSWORD`, `PROTON_2FA`, and `PROTON_MAILBOX_PASSWORD`, the container will automatically add your account to the bridge and print local connection info to the log. Note:
- The auto login feature only kicks in when the bridge has zero account added. If there is at least one account, auto login will be skipped. Changing the environmental variables will neither add another account to the bridge nor replace the account with the new one. To do so, use [CLI](#cli).
- Two factor authentication codes time out quickly (in 30 seconds). It is highly possible that the code is already expired at the time login take place. To help with that, you can try pull the image first before setting it. You can also wait for a new code so that the container will have full 30 seconds to boot up. If non of them works, try manual login with [CLI](#cli).
- If your container logs can be accessed by someone else, it is recommended to turn of the account info printing by set `PROTON_PRINT_ACCOUNT_INFO` to `false`. Then you can use [CLI](#cli) to fetch the account info.

### CLI

2.0 comes with a CLI to easily interact with the bridge. There is no need to modify the entrypoint, manually kill any process, or restart the container when you are done. Everything you need is to `exec` into the container and run `cli`. With that, you can add, remove, list accounts and print account info. Changing the address mode of an account is currently not supported. To do so, simply delete the account and add it back again. Example:
```
➜ docker exec -it protonmail cli
CLI to interacte with Proton Bridge HTTP REST interface
Available commands:
 login:            Calls up the login procedure to add or connect accounts.
 delete <account>: Remove the account from keychain. You can use index or account name as the parameter.
 list:             Print list of your accounts.
 info <account>:   Print account configuration. You can use index or account name as the parameter.
 help:             Print help messages.
 exit:             Exit the CLI

>> info bob
Configuration for bob@proton.me
IMAP port: 143
IMAP security: STARTTLS
SMTP port: 25
SMTP security: STARTTLS
Username:  bob@proton.me
Password:  xxxxxxxxxxxxxxxxxxxxxx

>> exit
```

### Migrate from old version

To migrate, you just need to change the mount path from `/root` to `/protonmail/data` and the container will do the rest of the work. Note that this is a one way trip. There is no way to get back to the old version. You'll need to set up everything again from scratch to go back. Also, any bridge preferences (e.g. whether to use a proxy) will not be migrated. You'll need to set them again with the environmental variables. Not all preferences are supported yet. Feel free to open an issue or PR for options you want to change. If anything goes sideways, it can be caused by problematic migrating steps. You can try to clear your volume and start everything from the scratch.

## Supported architectures

architecture | status | note
 -- | --
`amd64` | supported |
`arm64/v8` | supported |
`arm/v7` | supported | 32-bit platforms are no longer officially supported by Proton. Thanks to blumberg for the workaround [#40](https://github.com/shenxn/protonmail-bridge-docker/pull/40)
`riscv64` | WIP | Check progress at [#54](https://github.com/shenxn/protonmail-bridge-docker/pull/54)

## Legacy Documentation

This section contains information for the old version. They are kept here for reference and will be removed once 2.0 graduates from beta.

### Tags

There are two types of images.
 - `deb`: Images based on the official [.deb release](https://protonmail.com/bridge/install). It only supports the `amd64` architecture.
 - `build`: Images based on the [source code](https://github.com/ProtonMail/proton-bridge). It supports `amd64`, `arm64`, and `arm/v7`. Supporting to more architectures is possible. PRs are welcome.

tag | description
 -- | --
`latest` | latest `deb` image
`[version]` | `deb` images
`build` | latest `build` image
`[version]-build` | `build` images

### Initialization

To initialize and add account to the bridge, run the following command.

```
docker run --rm -it -v protonmail:/root shenxn/protonmail-bridge init
```

Wait for the bridge to startup, use `login` command and follow the instructions to add your account into the bridge. Then use `info` to see the configuration information (username and password). After that, use `exit` to exit the bridge. You may need `CTRL+C` to exit the docker entirely.

### Run

To run the container, use the following command.

```
docker run -d --name=protonmail-bridge -v protonmail:/root -p 1025:25/tcp -p 1143:143/tcp --restart=unless-stopped shenxn/protonmail-bridge
```

### Kubernetes

If you want to run this image in a Kubernetes environment. You can use the [Helm](https://helm.sh/) chart (https://github.com/k8s-at-home/charts/tree/master/charts/stable/protonmail-bridge) created by [@Eagleman7](https://github.com/Eagleman7). More details can be found in [#23](https://github.com/shenxn/protonmail-bridge-docker/issues/23).

If you don't want to use Helm, you can also reference to the guide ([#6](https://github.com/shenxn/protonmail-bridge-docker/issues/6)) written by [@ghudgins](https://github.com/ghudgins).

### Security

Please be aware that running the command above will expose your bridge to the network. Remember to use firewall if you are going to run this in an untrusted network or on a machine that has public IP address. You can also use the following command to publish the port to only localhost, which is the same behavior as the official bridge package.

```
docker run -d --name=protonmail-bridge -v protonmail:/root -p 127.0.0.1:1025:25/tcp -p 127.0.0.1:1143:143/tcp --restart=unless-stopped shenxn/protonmail-bridge
```

Besides, you can publish only port 25 (SMTP) if you don't need to receive any email (e.g. as a email notification service).

### Compatibility

The bridge currently only supports some of the email clients. More details can be found on the official website. I've tested this on a Synology DiskStation and it runs well. However, you may need ssh onto it to run the interactive docker command to add your account. The main reason of using this instead of environment variables is that it seems to be the best way to support two-factor authentication.

### Bridge CLI Guide

The initialization step exposes the bridge CLI so you can do things like switch between combined and split mode, change proxy, etc. The [official guide](https://protonmail.com/support/knowledge-base/bridge-cli-guide/) gives more information on to use the CLI.

### Build

For anyone who want to build this container on your own (for development or security concerns), here is the guide to do so. First, you need to `cd` into the directory (`deb` or `build`, depending on which type of image you want). Then just run the docker build command
```
docker build .
```

That's it. The `Dockerfile` and bash scripts handle all the downloading, building, and packing. You can also add tags, push to your favorite docker registry, or use `buildx` to build multi architecture images.
