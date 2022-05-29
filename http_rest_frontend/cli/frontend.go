// Package cli provides HTTP interface of the bridge
package cli

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/ProtonMail/proton-bridge/internal/config/settings"
	"github.com/ProtonMail/proton-bridge/internal/events"
	"github.com/ProtonMail/proton-bridge/internal/frontend/types"
	"github.com/ProtonMail/proton-bridge/internal/locations"
	"github.com/ProtonMail/proton-bridge/internal/updater"
	"github.com/ProtonMail/proton-bridge/pkg/listener"
	"github.com/julienschmidt/httprouter"
	"github.com/sirupsen/logrus"
)

type frontendCLI struct {
	*httprouter.Router

	locations     *locations.Locations
	settings      *settings.Settings
	eventListener listener.Listener
	updater       types.Updater
	bridge        types.Bridger
	restarter     types.Restarter
}

func New(
	panicHandler types.PanicHandler,

	locations *locations.Locations,
	settings *settings.Settings,
	eventListener listener.Listener,
	updater types.Updater,
	bridge types.Bridger,
	restarter types.Restarter,
) *frontendCLI {
	fe := &frontendCLI{
		Router:        httprouter.New(),
		locations:     locations,
		settings:      settings,
		eventListener: eventListener,
		updater:       updater,
		bridge:        bridge,
		restarter:     restarter,
	}

	fe.PUT("/accounts", fe.loginAccount)
	fe.GET("/accounts", fe.listAccounts)
	fe.GET("/accounts/:account", fe.showAccountInfo)
	fe.DELETE("/accounts/:account", fe.deleteAccount)

	return fe
}

func (f *frontendCLI) loginWithEnv() {
	if len(f.bridge.GetUsers()) > 0 {
		fmt.Println("More than 0 accounts found. Skip auto login.")
		return
	}
	username := os.Getenv("PROTON_USERNAME")
	password := os.Getenv("PROTON_PASSWORD")
	if username == "" {
		logrus.Info("PROTON_USERNAME and PROTON_PASSWORD are not set. Skip auto login.")
		return
	}
	client, auth, err := f.bridge.Login(username, []byte(password))
	if err != nil {
		f.processAPIError(err)
		logrus.WithError(err).Warn("Login failed.")
		return
	}

	if auth.HasTwoFactor() {
		twoFactor := os.Getenv("PROTON_2FA")
		if twoFactor == "" {
			logrus.Warn("Login failed: 2FA enabled for the account but PROTON_2FA was not set.")
			return
		}
		err = client.Auth2FA(context.Background(), twoFactor)
		if err != nil {
			f.processAPIError(err)
			logrus.WithError(err).Warn("Login failed.")
			return
		}
	}

	mailboxPassword := password
	if auth.HasMailboxPassword() {
		mailboxPassword = os.Getenv("PROTON_MAILBOX_PASSWORD")
		if mailboxPassword == "" {
			logrus.Warn("Login failed: Two password mode enabled but PROTON_MAILBOX_PASSWORD was not set.")
			return
		}
	}
	user, err := f.bridge.FinishLogin(client, auth, []byte(mailboxPassword))
	if err != nil {
		f.processAPIError(err)
		logrus.WithError(err).Warn("Login failed.")
		return
	}
	logrus.Infof("Account %s was added successfully.\n", user.Username())
	if strings.ToLower(os.Getenv("PROTON_PRINT_ACCOUNT_INFO")) != "false" {
		f.printAccountInfo(os.Stdout, user)
	}
}

func (f *frontendCLI) watchEvents() {
	errorCh := f.eventListener.ProvideChannel(events.ErrorEvent)
	credentialsErrorCh := f.eventListener.ProvideChannel(events.CredentialsErrorEvent)
	internetConnChangedCh := f.eventListener.ProvideChannel(events.InternetConnChangedEvent)
	addressChangedCh := f.eventListener.ProvideChannel(events.AddressChangedEvent)
	addressChangedLogoutCh := f.eventListener.ProvideChannel(events.AddressChangedLogoutEvent)
	logoutCh := f.eventListener.ProvideChannel(events.LogoutEvent)
	certIssue := f.eventListener.ProvideChannel(events.TLSCertIssue)
	for {
		select {
		case errorDetails := <-errorCh:
			logrus.Error("Bridge failed:", errorDetails)
		case <-credentialsErrorCh:
			f.notifyCredentialsError()
		case stat := <-internetConnChangedCh:
			if stat == events.InternetOff {
				f.notifyInternetOff()
			}
			if stat == events.InternetOn {
				f.notifyInternetOn()
			}
		case address := <-addressChangedCh:
			fmt.Printf("Address changed for %s. You may need to reconfigure your email client.", address)
		case address := <-addressChangedLogoutCh:
			f.notifyLogout(address)
		case userID := <-logoutCh:
			user, err := f.bridge.GetUser(userID)
			if err != nil {
				return
			}
			f.notifyLogout(user.Username())
		case <-certIssue:
			f.notifyCertIssue()
		}
	}
}

func (f *frontendCLI) Loop() error {
	f.loginWithEnv()
	managementPort := os.Getenv("PROTON_MANAGEMENT_PORT")
	if managementPort == "" {
		managementPort = "1080"
	}
	http.ListenAndServe(":"+managementPort, f)
	return nil
}

func (f *frontendCLI) NotifyManualUpdate(update updater.VersionInfo, canInstall bool) {}
func (f *frontendCLI) WaitUntilFrontendIsReady()                                      {}
func (f *frontendCLI) SetVersion(version updater.VersionInfo)                         {}
func (f *frontendCLI) NotifySilentUpdateInstalled()                                   {}
func (f *frontendCLI) NotifySilentUpdateError(err error)                              {}
