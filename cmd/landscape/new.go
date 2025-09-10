package main

import (
	"context"
	"fmt"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/jansdhillon/landscape-demo/internal/config"
	"github.com/jansdhillon/landscape-demo/internal/server"
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
		ec := cli.Exit(fmt.Sprintf("error getting terraform.tfvars.json path: %v\n", err), 0)
		return ec
	}
	vars, err := config.ParseTfJsonVars(tfVarsPath)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error parsing terraform.tfvars.json: %v\n", err), 0)
		return ec
	}

	fmt.Fprintf(cmd.Root().Writer, "vars: %v\n", vars)

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

	workspaceName := cmd.Args().Get(0)

	if workspaceName == "" {
		workspaceName = vars.WorkspaceName
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

	var deployOpts []server.DeployServerOption
	deployOpts = append(deployOpts, server.NewDeployServerOpt(&vars.B64SSLCert, &vars.B64SSLKey, &vars.GPGPrivateKeyContent))
	err = server.DeployLandscapeServer(ctx, tf, workspaceName, deployOpts...)
	if err != nil {
		ec := cli.Exit(fmt.Sprintf("error deploying Landscape Server: %v", err), 1)
		return ec
	}

	return nil
}
