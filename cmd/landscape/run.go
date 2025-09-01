package main

import (
	"context"
	"fmt"

	"os"

	"errors"

	"github.com/jansdhillon/landscape-demo/internal/config"
	"github.com/urfave/cli/v3"
	"github.com/zclconf/go-cty/cty/gocty"
)

var runCmd = &cli.Command{
	Name:   "run",
	Usage:  "Run the workspace.",
	Action: actionRun,
}

func actionSetupTf(ctx context.Context, cmd *cli.Command) error {
	if _, err := os.Stat(config.TfVarsFileName); errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("tfvars file not found: %w", err)
	}

	module := &config.LandscapeDemoModule{
		TfVarsPath:   "terraform.tfvars",
		TerraformDir: "./",
	}

	val, err := module.GetModuleValue(ctx, "hello")
	if err != nil {
		return fmt.Errorf("error reading module varible: %v", err)
	}
	var token string
	err = gocty.FromCtyValue(val, &token)
	if err != nil {
		return fmt.Errorf("error getting pro token: %v", err)
	}
	fmt.Printf("Token: %s\n", token)

	return nil
}

func actionRun(ctx context.Context, cmd *cli.Command) error {
	err := actionSetupTf(ctx, cmd)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error setting up terraform: %v", err), 1)
		return ec
	}

	return nil
}
