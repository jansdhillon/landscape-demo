package main

import (
	"fmt"

	"github.com/jansdhillon/landscape-demo/internal/log"
)

func initLogger(level string) error {
	l, err := log.ParseLevel(level)
	if err != nil {
		return fmt.Errorf("'%s' is not a valid log level", level)
	}

	log.Setup(l, false)

	return nil
}
