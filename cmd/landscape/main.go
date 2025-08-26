package main

import (
	"context"
	"log"
	"log/slog"
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
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    logLevelFlag,
				Aliases: []string{"l"},
				Value:   slog.LevelInfo.String(),
				Usage:   "Log level.",
			},
		},
	}
}

func actionSetup(cmd *cli.Command) error {
	err := initLogger(cmd.String(logLevelFlag))
	if err != nil {
		return err
	}

	return nil
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
