package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"github.com/gamekube/gamekube/internal"
	"github.com/gamekube/gamekube/internal/controller"
	"github.com/gamekube/gamekube/internal/server"
	"github.com/urfave/cli/v2"
)

// logLevel is the text representation of a [slog.Level]
type logLevel string

// Gets the [slog.Level] for the given [logLevel].
func (ll logLevel) GetSlogLevel() (slog.Level, error) {
	ls := ll
	if ls == "" {
		ls = "info"
	}

	var sl slog.Level
	var err error
	switch ls {
	case "error":
		sl = slog.LevelError
	case "warn":
		sl = slog.LevelWarn
	case "info":
		sl = slog.LevelInfo
	case "debug":
		sl = slog.LevelDebug
	default:
		err = fmt.Errorf("unrecognized log level %s", ls)
	}

	return sl, err
}

// loggerKey is the [cli.Context] key where the created logger is stored
type loggerKey struct{}

func main() {
	err := (&cli.App{
		Before: func(c *cli.Context) error {
			sl, err := logLevel(c.String("log-level")).GetSlogLevel()
			if err != nil {
				return err
			}
			logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: sl}))
			c.Context = context.WithValue(c.Context, loggerKey{}, logger)
			return nil
		},
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    "log-level",
				Usage:   "logging verbosity level",
				EnvVars: []string{"GAMEKUBE_LOG_LEVEL"},
			},
		},
		Commands: []*cli.Command{
			{
				Name:  "controller",
				Usage: "starts controller",
				Flags: []cli.Flag{},
				Action: func(c *cli.Context) error {
					l, ok := c.Context.Value(loggerKey{}).(*slog.Logger)
					if !ok {
						return fmt.Errorf("logger not attached to context")
					}

					controller, err := controller.New(&controller.Opts{
						Logger: l,
					})
					if err != nil {
						return err
					}

					return controller.Run(context.Background())
				},
			},
			{
				Name:  "server",
				Usage: "starts server",
				Flags: []cli.Flag{},
				Action: func(c *cli.Context) error {
					l, ok := c.Context.Value(loggerKey{}).(*slog.Logger)
					if !ok {
						return fmt.Errorf("logger not attached to context")
					}

					server, err := server.New(&server.Opts{
						Logger: l,
					})
					if err != nil {
						return err
					}

					return server.Run(context.Background())
				},
			},
			{
				Name:  "version",
				Usage: "prints version",
				Action: func(c *cli.Context) error {
					fmt.Fprintf(c.App.Writer, "%s", internal.GetVersion())
					return nil
				},
			},
		},
	}).Run(os.Args)
	code := 0
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %s\n", err.Error())
		code = 1
	}
	os.Exit(code)
}
