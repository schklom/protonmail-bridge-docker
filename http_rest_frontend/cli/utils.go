package cli

import (
	"github.com/ProtonMail/proton-bridge/pkg/pmapi"
	"github.com/sirupsen/logrus"
)

func (f *frontendCLI) processAPIError(err error) {
	switch err {
	case pmapi.ErrNoConnection:
		f.notifyInternetOff()
	case pmapi.ErrUpgradeApplication:
		f.notifyNeedUpgrade()
	}
}

func (f *frontendCLI) notifyInternetOff() {
	logrus.Warn("Internet connection is not available.")
}

func (f *frontendCLI) notifyInternetOn() {
	logrus.Info("Internet connection is available again.")
}

func (f *frontendCLI) notifyLogout(address string) {
	logrus.Infof("Account %s is disconnected. Login to continue using this account with email client.", address)
}

func (f *frontendCLI) notifyNeedUpgrade() {
	logrus.Info("Upgrade needed. Please download and install the newest version of application.")
}

func (f *frontendCLI) notifyCredentialsError() {
	logrus.Error(`ProtonMail Bridge is not able to detect a supported password manager
(secret-service or pass). Please install and set up a supported password manager
and restart the application.
`)
}

func (f *frontendCLI) notifyCertIssue() {
	// Print in 80-column width.
	logrus.Error(`Connection security error: Your network connection to Proton services may
be insecure.

Description:
ProtonMail Bridge was not able to establish a secure connection to Proton
servers due to a TLS certificate error. This means your connection may
potentially be insecure and susceptible to monitoring by third parties.

Recommendation:
* If you trust your network operator, you can continue to use ProtonMail
  as usual.
* If you don't trust your network operator, reconnect to ProtonMail over a VPN
  (such as ProtonVPN) which encrypts your Internet connection, or use
  a different network to access ProtonMail.
`)
}
