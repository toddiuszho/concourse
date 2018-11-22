package atc

type WorkerArtifact struct {
	ID        int    `json:"id"`
	Path      string `json:"path"`
	CreatedAt int    `json:"created_at"`
	Checksum  string `json:"checksum"`
}
