package controller

import (
	"context"
	"log/slog"
)

type Controller interface {
	Run(ctx context.Context) error
}

type controller struct {
}

type Opts struct {
	Logger *slog.Logger
}

func New(opts *Opts) (Controller, error) {
	return nil, nil
}

func (c *controller) Run(ctx context.Context) error {
	return nil
}
