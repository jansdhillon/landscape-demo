package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/urfave/cli/v3"
)

const (
	TerraformVersion = "1.12.0"
	TfVarsFileName   = "terraform.tfvars.json"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	app := &cli.Command{
		Name: "landscape",
		Commands: []*cli.Command{
			serverCmd,
		},
	}

	if err := app.Run(ctx, os.Args); err != nil {
		log.Fatal(err)
	}
}
