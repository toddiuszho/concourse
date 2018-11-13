package worker

import (
	"net/http"

	gclient "code.cloudfoundry.org/garden/client"
	"code.cloudfoundry.org/lager"
	bclient "github.com/concourse/baggageclaim/client"
)

type healthChecker struct {
	baggageclaim bclient.Client
	garden       gclient.Client
	logger       lager.Logger
}

func NewHealthChecker(logger lager.Logger, bc bclient.Client, gc gclient.Client) (h healthChecker) {
	return healthChecker{
		logger:       logger,
		baggageclaim: bc,
		garden:       gc,
	}
}

func (h *healthChecker) CheckHealth(w http.ResponseWriter, req *http.Request) {
	var err error

	// CC: log?
	err = h.garden.Ping()
	if err != nil {
		w.WriteHeader(503)
		return
	}

	_, err = h.baggageclaim.ListVolumes(h.logger, nil)
	if err != nil {
		w.WriteHeader(503)
		return
	}

	return
}
