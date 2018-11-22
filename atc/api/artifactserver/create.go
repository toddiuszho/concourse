package artifactserver

import (
	"encoding/json"
	"net/http"

	"github.com/concourse/baggageclaim"
	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/db"
	"github.com/concourse/concourse/atc/worker"
)

func (s *Server) CreateArtifact(team db.Team) http.Handler {
	hLog := s.logger.Session("create-artifact")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		spec := worker.VolumeSpec{
			Strategy: baggageclaim.EmptyStrategy{},
		}

		volume, err := s.workerClient.CreateVolume(hLog, spec, team.ID(), db.VolumeTypeArtifact)
		if err != nil {
			hLog.Error("failed-to-create-volume", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		// TODO: can probably check if fly sent us an etag header
		// and store it in the checksum field.
		// that way we don't have to create another volume.
		artifact, err := volume.InitializeArtifact("/", "")
		if err != nil {
			hLog.Error("failed-to-initialize-artifact", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		err = volume.StreamIn("/", r.Body)
		if err != nil {
			hLog.Error("failed-to-stream-volume-contents", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)

		json.NewEncoder(w).Encode(atc.WorkerArtifact{
			ID:        artifact.ID(),
			Checksum:  "",
			Path:      "/",
			CreatedAt: artifact.CreatedAt(),
		})
	})
}
