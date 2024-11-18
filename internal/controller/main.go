package controller

import (
	"context"
	"io"
	"log/slog"

	"github.com/gamekube/gamekube/internal/reconcilers"
	v1 "github.com/gamekube/gamekube/pkg/api/gamekube.dev/v1"
	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/tools/clientcmd"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/metrics/server"
)

// Controller is the public interface of the controller component
type Controller interface {
	Run(ctx context.Context) error
}

// controller provides the implementation of [Controller]
type controller struct {
	logger  *slog.Logger
	manager manager.Manager
}

// Opts are the options used to construct a new [Controller]
// See: [New]
type Opts struct {
	HealthBindAddress string
	Kubeconfig        string
	Logger            *slog.Logger
}

// Creates a new [Controller] with the given [Opts]
func New(opts *Opts) (Controller, error) {
	logger := opts.Logger
	if logger == nil {
		logger = slog.New(slog.NewTextHandler(io.Discard, &slog.HandlerOptions{}))
	}

	clientCfg, err := clientcmd.BuildConfigFromFlags("", opts.Kubeconfig)
	if err != nil {
		return nil, err
	}
	scheme := runtime.NewScheme()
	err = v1.AddToScheme(scheme)
	if err != nil {
		return nil, err
	}

	healthBindAddress := opts.HealthBindAddress
	if healthBindAddress == "" {
		healthBindAddress = ":8888"
	}

	manager, err := manager.New(clientCfg, manager.Options{
		HealthProbeBindAddress: healthBindAddress,
		Logger:                 logr.FromSlogHandler(logger.Handler()),
		Metrics:                server.Options{BindAddress: "0"},
		Scheme:                 scheme,
	})
	if err != nil {
		return nil, err
	}
	err = manager.AddHealthzCheck("healthz", healthz.Ping)
	if err != nil {
		return nil, err
	}
	err = manager.AddReadyzCheck("readyz", healthz.Ping)
	if err != nil {
		return nil, err
	}

	reconcilers := []reconcilers.Reconciler{
		&reconcilers.Game{},
	}
	for _, reconciler := range reconcilers {
		err = reconciler.Register(manager)
		if err != nil {
			return nil, err
		}
	}

	return &controller{
		logger:  logger,
		manager: manager,
	}, err
}

// Runs the controller.
// Blocks until the the provided [context.Context] is cancelled.
func (c *controller) Run(ctx context.Context) error {
	c.logger.Info("starting operator")
	return c.manager.Start(ctx)
}
