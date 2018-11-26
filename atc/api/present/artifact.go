package present

import (
	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/db"
)

func Artifact(artifact db.WorkerArtifact) atc.WorkerArtifact {

	atcWorkerArtifact := atc.WorkerArtifact{
		ID:       artifact.ID(),
		Path:     artifact.Path(),
		Checksum: artifact.Checksum(),
	}

	if !artifact.CreatedAt().IsZero() {
		atcWorkerArtifact = artifact.CreatedAt().Unix()
	}

	return atcWorkerArtifact
}
