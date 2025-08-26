package main

import (
	"context"
	"fmt"

	"os"

	"errors"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/jansdhillon/landscape-demo/internal/config"
	"github.com/urfave/cli/v3"
)

var newCmd = &cli.Command{
	Name:   "new",
	Usage:  "Create a new workspace.",
	Action: actionNew,
}

func actionNew(_ context.Context, cmd *cli.Command) (err error) {
	workingDir, err := config.TerraformDirectory()
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error getting working directory: %v\n", err), 0)
		return ec
	}
	if _, err := os.Stat(config.TfVarsFileName); errors.Is(err, os.ErrNotExist) {
		ec := cli.Exit(fmt.Sprintf("error checking for tfvars: %v\n", err), 0)
		return ec
	}
	fmt.Fprintf(cmd.Root().Writer, "%s found!\n", config.TfVarsFileName)

	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.0.6")),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error installing tf: %v\n", err), 0)
		return ec
	}

	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error creating tf: %v\n", err), 0)
		return ec
	}

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error initializing workspace: %v\n", err), 0)
		return ec
	}

	state, err := tf.Show(context.Background())
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error running show: %v\n", err), 0)
		return ec
	}

	fmt.Fprintf(cmd.Root().Writer, "state: %v\n", state)

	return nil
}
