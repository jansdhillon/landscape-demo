package main

import (
	"context"
	"fmt"
	"log"

	"os"

	"errors"

	"github.com/jansdhillon/landscape-demo/internal/config"
	"github.com/urfave/cli/v3"
	"github.com/zclconf/go-cty/cty"
)

var runCmd = &cli.Command{
	Name:   "run",
	Usage:  "Run the workspace.",
	Action: actionRun,
}

func actionRun(_ context.Context, cmd *cli.Command) (err error) {
	if _, err := os.Stat(config.TfVarsFileName); errors.Is(err, os.ErrNotExist) {
		return cli.Exit(fmt.Sprintf("error checking for tfvars: %v", err), 0)
	}
	fmt.Fprintf(cmd.Root().Writer, "%s found!", config.TfVarsFileName)
	vars, err := config.ParseHCLTfvars(config.TfVarsFileName)
	if err != nil {
		log.Fatalf("Error parsing tfvars: %s", err)
	}

	if helloVal, exists := vars["hello"]; exists {
		log.Printf("Current value of 'hello': %s", helloVal.AsString())
	}

	vars["hello"] = cty.StringVal("updated_world")

	err = config.WriteHCLTfVars(config.TfVarsFileName, vars)
	if err != nil {
		log.Fatalf("Error writing tfvars: %s", err)
	}
	return nil
}
