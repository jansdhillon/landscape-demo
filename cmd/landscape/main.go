package main

import (
	"context"
	"log"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/jansdhillon/landscape-demo/internal/landscape"
)

const (
	TerraformVersion = "1.12.0"
	TfVarsFileName   = "terraform.tfvars"
)

func main() {
	ctx := context.Background()

	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion(TerraformVersion)),
	}

	execPath, err := installer.Install(ctx)
	if err != nil {
		log.Fatalf("Error installing Terraform: %s", err)
	}

	baseWorkingDir, err := os.Getwd()
	if err != nil {
		log.Fatalf("Error getting current working directory: %s", err)
	}

	terraformDir := filepath.Join(baseWorkingDir, "terraform")

	modulePath := filepath.Join(terraformDir, "server")

	tfVarsFilePath := filepath.Join(baseWorkingDir, TfVarsFileName)

	if _, err := os.Stat(tfVarsFilePath); os.IsNotExist(err) {
		log.Fatalf("Terraform variables file does not exist: %s", tfVarsFilePath)
	}

	logger := log.New(os.Stdout, "", log.LstdFlags)

	landscapeServer, err := (&landscape.LandscapeServer{}).New(ctx, modulePath, tfVarsFilePath, "/etc/letsencrypt/live/landscape.jandhillon.com/cert.pem", "/etc/letsencrypt/live/landscape.jandhillon.com/privkey.pem", execPath, logger)

	if err != nil {
		log.Fatalf("Error creating the Landscape Server module: %s", err)
	}

	landscapeServer.Init()

	landscapeServer.Plan()

	landscapeServer.Apply()

	landscapeClient, err := (&landscape.LandscapeClient{}).New(ctx, modulePath, tfVarsFilePath, execPath, logger, true)
	if err != nil {
		log.Fatalf("Error creating the Landscape Client module: %s", err)
	}

	landscapeClient.Init()

	landscapeClient.Plan()

	landscapeClient.Apply()

	log.Default().Println("Done!")

}
