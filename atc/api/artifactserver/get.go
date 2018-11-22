package artifactserver

import (
	"encoding/json"
	"net/http"

	"github.com/concourse/concourse/atc/db"
)

func (s *Server) GetArtifact(team db.Team) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logger := s.logger.Session("get-artifact")

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)

		err := json.NewEncoder(w).Encode("")
		if err != nil {
			logger.Error("failed-to-encode-artifact", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
	})
}
