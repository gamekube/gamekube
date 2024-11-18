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
	logger := opts.Logger
	if logger == nil {
		logger = slog.New(slog.NewTextHandler(io.Discard, nil))
	}

	bindAddress := opts.BindAddress
	if bindAddress == "" {
		bindAddress = ":8080"
	}

	echo := echo.New()
	echo.HideBanner = true
	echo.HidePort = true

	server := server{
		bindAddress: bindAddress,
		echo:        echo,
		logger:      logger,
	}

	staticFs, err := internal.GetStaticFS()
	if err != nil {
		return nil, err
	}

	echo.Use(slogecho.New(logger))
	echo.Use(middleware.StaticWithConfig(middleware.StaticConfig{
		Browse:     true,
		HTML5:      true,
		Filesystem: http.FS(staticFs),
	}))

	echo.GET("/healthz", server.health)

	return &server, nil
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
