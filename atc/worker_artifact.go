package atc

type WorkerArtifact struct {
	ID        int    `json:"id"`
	Path      string `json:"path"`
	CreatedAt int64  `json:"created_at"`
	Checksum  string `json:"checksum"`
}
