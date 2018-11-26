package artifactserver

import (
	"encoding/json"
	"net/http"
	"strconv"

	"code.cloudfoundry.org/lager"
	"github.com/concourse/concourse/atc/api/present"
	"github.com/concourse/concourse/atc/db"
)

func (s *Server) GetArtifact(team db.Team) http.Handler {
	logger := s.logger.Session("get-artifact")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		w.Header().Set("Content-Type", "application/json")

		artifactID, err := strconv.Atoi(r.FormValue(":artifact_id"))
		if err != nil {
			logger.Error("failed-to-get-artifact-id", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		artifact, found, err := team.WorkerArtifact(artifactID)
		if err != nil {
			logger.Error("failed-to-get-artifact", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		if !found {
			logger.Debug("artifact-not-found", lager.Data{"artifact_id": artifactID})
			w.WriteHeader(http.StatusNotFound)
			return
		}

		err = json.NewEncoder(w).Encode(present.Artifact(artifact))
		if err != nil {
			logger.Error("failed-to-encode-artifact", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
	})
}
