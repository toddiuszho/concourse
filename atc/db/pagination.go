package db

type Page struct {
	// TODO [cc,by]: convert to uint64
	Since int // exclusive
	Until int // exclusive

	From int // inclusive
	To   int // inclusive

	Limit int
}

type Pagination struct {
	Previous *Page
	Next     *Page
}
