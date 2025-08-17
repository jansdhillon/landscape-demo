package landscape

import (
	"log"
	"os"
	"path/filepath"

	"github.com/jansdhillon/landscape-demo/internal/config"
)

func CheckForTfVars() error {
	baseWorkingDir, err := os.Getwd()
	if err != nil {
		log.Fatalf("Error getting current working directory: %s", err)
	}

	tfVarsFilePath := filepath.Join(baseWorkingDir, config.TfVarsFileName)

	if _, err := os.Stat(tfVarsFilePath); os.IsNotExist(err) {
		log.Fatalf("Terraform variables file does not exist: %s", tfVarsFilePath)
	}

	return nil
}
