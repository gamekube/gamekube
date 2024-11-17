package controller

import (
	"context"
	"io"
	"log/slog"
)

// Controller is the public interface of the controller component
type Controller interface {
	Run(ctx context.Context) error
}

// controller provides the implementation of [Controller]
type controller struct {
	logger *slog.Logger
}

// Opts are the options used to construct a new [Controller]
// See: [New]
type Opts struct {
	Logger *slog.Logger
}

// Creates a new [Controller] with the given [Opts]
func New(opts *Opts) (Controller, error) {
	l := opts.Logger
	if l == nil {
		l = slog.New(slog.NewTextHandler(io.Discard, &slog.HandlerOptions{}))
	}

	c := controller{
		logger: l,
	}

	return &c, nil
}

// Runs the controller.
// Blocks until the the provided [context.Context] is cancelled.
func (c *controller) Run(ctx context.Context) error {
	return nil
}
