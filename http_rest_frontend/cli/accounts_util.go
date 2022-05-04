package cli

import (
	"strconv"

	"github.com/ProtonMail/proton-bridge/internal/frontend/types"
)

func (f *frontendCLI) getUserByIndexOrName(account string) types.User {
	users := f.bridge.GetUsers()
	numberOfAccounts := len(users)
	if index, err := strconv.Atoi(account); err == nil {
		if index < 0 || index >= numberOfAccounts {
			return nil
		}
		return users[index]
	}
	for _, user := range users {
		if user.Username() == account {
			return user
		}
	}
	return nil
}
