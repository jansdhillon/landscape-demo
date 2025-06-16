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

	ls, err := (&landscape.LandscapeServer{}).New(ctx, modulePath, tfVarsFilePath, "/etc/letsencrypt/live/landscape.jandhillon.com/cert.pem", "/etc/letsencrypt/live/landscape.jandhillon.com/privkey.pem", execPath, log.New(os.Stdout, "", log.LstdFlags))

	if err != nil {
		log.Fatalf("Error creating the Landscape Server module: %s", err)
	}

	initErr := ls.Init()

	if initErr != nil {
		log.Fatalf("Error running Init: %s", initErr)
	}

	planErr := ls.Plan()

	if planErr != nil {
		log.Fatalf("Error running Plan: %s", planErr)
	}

}
