package main

import (
	"context"
	"fmt"

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

func actionNew(ctx context.Context, cmd *cli.Command) (err error) {
	tfVarsPath, err := config.TfVarsPath()
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error getting terraform.tfvars path: %v\n", err), 0)
		return ec
	}

	fmt.Fprintf(cmd.Root().Writer, "%s found!\n", tfVarsPath)

	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion(config.TerraformVersion)),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		return err
	}

	wd, err := config.TerraformDirectory()
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error gettings terraform directory: %v", err), 0)
		return ec
	}
	tf, err := tfexec.NewTerraform(wd, execPath)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error creating tf: %v\n", err), 0)
		return ec
	}

	err = tf.Init(ctx, tfexec.Upgrade(true))
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error initializing workspace: %v\n", err), 0)
		return ec
	}

	m := config.LandscapeDemoModule{
		TfVarsPath:   tfVarsPath,
		TerraformDir: wd,
	}

	workspaceName := cmd.Args().Get(0)

	if workspaceName == "" {
		val, err := m.GetModuleValue(ctx, "hello")
		if err != nil {
			return fmt.Errorf("error getting module variable: %w", err)
		}

		workspaceName = val.AsString()
	}

	err = tf.WorkspaceNew(ctx, workspaceName)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error creating workspace: %v", err), 1)
		return ec
	}

	state, err := tf.Show(ctx)
	if err != nil {
		return err
	}

	fmt.Fprintf(cmd.Root().Writer, "state: %v\n", state)

	return nil
}
