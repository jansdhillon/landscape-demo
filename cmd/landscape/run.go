package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jansdhillon/landscape-demo/internal/config"
	"github.com/jansdhillon/landscape-demo/internal/landscape"
	"github.com/urfave/cli/v3"
)

var runCmd = &cli.Command{
	Name:   "run",
	Usage:  "Run the workspace.",
	Action: actionRun,
}

func actionRun(_ context.Context, c *cli.Command) (err error) {
	err = landscape.CheckForTfVars()
	if err != nil {
		return cli.Exit(fmt.Sprintf("error checking for tfvars: %v", err), 0)
	}
	log.Printf("%s found!", config.TfVarsFileName)
	return nil
}
