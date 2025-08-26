package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"

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
	err = actionSetup(cmd)
	if err != nil {
		return err
	}
	workingDir, err := config.TerraformDirectory()
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error getting working directory: %v\n", err), 0)
		return ec
	}

	slog.Debug("Working dir set!", slog.String("working dir", workingDir))

	tfVarsPath, err := config.TfVarsPath(workingDir)
	if err != nil {
		ec := cli.Exit(err, 1)
		return ec
	}
	fmt.Fprintf(cmd.Root().Writer, "%s found! %s\n", config.TfVarsFileName, tfVarsPath)

	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion(config.TerraformVersion)),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		return err
	}

	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		return err
	}

	tf.SetLogger(log.Default())

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		return err
	}

	err = tf.Apply(context.Background(), tfexec.Var("hello=world"))
	if err != nil {
		return err
	}

	state, err := tf.Show(context.Background())
	if err != nil {
		return err
	}

	fmt.Fprintf(cmd.Root().Writer, "state: %v\n", state)

	return nil
}
