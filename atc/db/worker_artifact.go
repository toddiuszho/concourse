package db

import (
	"database/sql"

	sq "github.com/Masterminds/squirrel"
	"github.com/concourse/concourse/atc"
)

//go:generate counterfeiter . WorkerArtifact

type WorkerArtifact interface {
	ID() int
	Path() string
	Checksum() string
	CreatedAt() int
}

type artifact struct {
	conn Conn

	id        int
	path      string
	createdAt int
	checksum  string
}

func (a *artifact) ID() int          { return a.id }
func (a *artifact) Path() string     { return a.path }
func (a *artifact) Checksum() string { return a.checksum }
func (a *artifact) CreatedAt() int   { return a.createdAt }

func saveWorkerArtifact(tx Tx, atcArtifact atc.WorkerArtifact, conn Conn) (WorkerArtifact, error) {

	var artifactID int

	err := psql.Insert("worker_artifacts").
		SetMap(map[string]interface{}{
			"path":     atcArtifact.Path,
			"checksum": atcArtifact.Checksum,
		}).
		Suffix("RETURNING id").
		RunWith(tx).
		QueryRow().
		Scan(&artifactID)

	if err != nil {
		return nil, err
	}

	artifact, found, err := getWorkerArtifact(tx, artifactID, conn)

	if err != nil {
		return nil, err
	}

	if !found {
		return nil, nil
	}

	return artifact, nil
}

func getWorkerArtifact(tx Tx, id int, conn Conn) (WorkerArtifact, bool, error) {
	artifact := &artifact{conn: conn}

	err := psql.Select("id", "created_at", "path", "checksum").
		From("worker_artifacts").
		Where(sq.Eq{
			"id": id,
		}).
		RunWith(tx).
		QueryRow().
		Scan(&artifact.id, &artifact.createdAt, &artifact.path, &artifact.checksum)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, false, nil
		}

		return nil, false, err
	}

	return artifact, true, nil
}
