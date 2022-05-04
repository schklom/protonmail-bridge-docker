// Package cli provides HTTP interface of the bridge
package cli

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/ProtonMail/proton-bridge/internal/config/settings"
	"github.com/ProtonMail/proton-bridge/internal/frontend/types"
	"github.com/julienschmidt/httprouter"
)

func (f *frontendCLI) loginAccount(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "ParseForm() err: %v", err)
		return
	}
	username := r.FormValue("username")
	password := r.FormValue("password")
	twoFactor := r.FormValue("two-factor")
	mailboxPassword := r.FormValue("mailbox-password")
	client, auth, err := f.bridge.Login(username, []byte(password))
	if err != nil {
		f.processAPIError(err)
		w.WriteHeader(http.StatusUnauthorized)
		fmt.Fprintln(w, "Server error:", err.Error())
		return
	}

	if auth.HasTwoFactor() {
		if twoFactor == "" {
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintln(w, "2FA enabled for the account but a 2FA code was not provided.")
			return
		}
		err = client.Auth2FA(context.Background(), twoFactor)
		if err != nil {
			f.processAPIError(err)
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintln(w, "Server error:", err.Error())
			return
		}
	}

	if auth.HasMailboxPassword() {
		if mailboxPassword == "" {
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintln(w, "Two password mode enabled but a mailbox password was not provided.")
			return
		}
	} else {
		mailboxPassword = password
	}
	user, err := f.bridge.FinishLogin(client, auth, []byte(mailboxPassword))
	if err != nil {
		f.processAPIError(err)
		w.WriteHeader(http.StatusUnauthorized)
		fmt.Fprintln(w, "Server error:", err.Error())
		return
	}
	fmt.Fprintf(w, "Account %s was added successfully.\n", user.Username())
	f.printAccountInfo(w, user)
}

func (f *frontendCLI) deleteAccount(w http.ResponseWriter, r *http.Request, params httprouter.Params) {
	account := params.ByName("account")
	user := f.getUserByIndexOrName(account)
	if user == nil {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, "Account %s does not exist.\n", account)
		return
	}
	account = user.Username()
	if err := f.bridge.DeleteUser(user.ID(), true); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, "Cannot delete account: ", err)
		return
	}
	fmt.Fprintf(w, "Account %s was deleted successfully.\n", account)
}

func (f *frontendCLI) listAccounts(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	users := f.bridge.GetUsers()
	if len(users) == 0 {
		fmt.Fprintln(w, "No account found.")
		return
	}
	spacing := "%-2d: %-20s (%-15s, %-15s)\n"
	fmt.Fprintf(w, strings.ReplaceAll(spacing, "d", "s"), "#", "account", "status", "address mode")
	for idx, user := range users {
		connected := "disconnected"
		if user.IsConnected() {
			connected = "connected"
		}
		mode := "split"
		if user.IsCombinedAddressMode() {
			mode = "combined"
		}
		fmt.Fprintf(w, spacing, idx, user.Username(), connected, mode)
	}
}

func (f *frontendCLI) showAccountInfo(w http.ResponseWriter, r *http.Request, params httprouter.Params) {
	account := params.ByName("account")
	user := f.getUserByIndexOrName(account)
	if user == nil {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(w, "Account %s does not exist.\n", account)
		return
	}
	if !user.IsConnected() {
		fmt.Fprintf(w, "Please login to %s to get email client configuration.\n", user.Username())
		return
	}
	f.printAccountInfo(w, user)
}

func (f *frontendCLI) printAccountInfo(w io.Writer, user types.User) {
	if user.IsCombinedAddressMode() {
		f.printAccountAddressInfo(w, user, user.GetPrimaryAddress())
	} else {
		for _, address := range user.GetAddresses() {
			f.printAccountAddressInfo(w, user, address)
		}
	}
}

func (f *frontendCLI) printAccountAddressInfo(w io.Writer, user types.User, address string) {
	fmt.Fprintln(w, "Configuration for", address)
	smtpSecurity := "STARTTLS"
	if f.settings.GetBool(settings.SMTPSSLKey) {
		smtpSecurity = "SSL"
	}
	fmt.Fprintf(w, "IMAP port: %d\nIMAP security: %s\nSMTP port: %d\nSMTP security: %s\nUsername:  %s\nPassword:  %s\n",
		143,
		"STARTTLS",
		25,
		smtpSecurity,
		address,
		user.GetBridgePassword(),
	)
	fmt.Fprintln(w, "")
}
