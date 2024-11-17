package server

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/gamekube/gamekube/internal"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	slogecho "github.com/samber/slog-echo"
)

// The public interface of a server component
type Server interface {
	Run(ctx context.Context) error
}

// server provides the implementation of [Server]
type server struct {
	bindAddress string
	echo        *echo.Echo
	logger      *slog.Logger
}

// Opts are the options used to construct a new [Server]
// See: [New]
type Opts struct {
	BindAddress string
	Logger      *slog.Logger
}

// Creates a new [Server] with the given [Opts]
func New(opts *Opts) (Server, error) {
	l := opts.Logger
	if l == nil {
		l = slog.New(slog.NewTextHandler(io.Discard, nil))
	}

	ba := opts.BindAddress
	if ba == "" {
		ba = ":8080"
	}

	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	s := server{
		bindAddress: ba,
		echo:        e,
		logger:      l,
	}

	staticFs, err := internal.GetStaticFS()
	if err != nil {
		return nil, err
	}

	e.Use(slogecho.New(l))
	e.Use(middleware.StaticWithConfig(middleware.StaticConfig{
		Browse:     true,
		HTML5:      true,
		Filesystem: http.FS(staticFs),
	}))

	e.GET("/healthz", s.health)

	return &s, nil
}

// Implements a simple health endpoint
func (s *server) health(c echo.Context) error {
	return c.String(http.StatusOK, "ok")
}

// Runs the server.
// Blocks until the the provided [context.Context] is cancelled, or the underlying [echo.Server] stops running with an error.
func (s *server) Run(ctx context.Context) error {
	var err error
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		s.logger.Info(fmt.Sprintf("starting server: %s", s.bindAddress))
		err = s.echo.Start(s.bindAddress)
	}()

	ticker := time.NewTicker(100 * time.Millisecond)
	for {
		<-ticker.C
		if err != nil {
			break
		}

		select {
		case <-ctx.Done():
			err = context.Canceled
		default:
		}

		if err != nil {
			break
		}
	}

	ticker.Stop()
	s.echo.Shutdown(context.Background())
	wg.Wait()

	if err == context.Canceled {
		err = nil
	}

	return err
}
