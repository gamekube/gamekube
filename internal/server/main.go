package server

import (
	"context"
	"log/slog"
)

type Server interface {
	Run(ctx context.Context) error
}

type server struct {
}

type Opts struct {
	Logger *slog.Logger
}

func New(opts *Opts) (Server, error) {
	return nil, nil
}

func (s *server) Run(ctx context.Context) error {
	return nil
}
