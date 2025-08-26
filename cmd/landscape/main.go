package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/urfave/cli/v3"
)

// Flags
const (
	logLevelFlag = "log-level"
)

func newApp() *cli.Command {
	return &cli.Command{
		Usage: "Demo Landscape",
		Commands: []*cli.Command{
			runCmd,
			newCmd,
		},
	}
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	app := newApp()
	err := app.Run(ctx, os.Args)
	if err != nil {
		log.Fatalf("Execution completed with error(s): %v", err)
	}
}
