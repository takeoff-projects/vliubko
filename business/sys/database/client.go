package omslitedb

import (
	"database/sql"
	"fmt"
	"log"
)

// InitDB sets up setting up the connection pool global variable.
func InitDB(dataSource string) (*Queries, error) {
	log.Printf("Connecting to the DB with connection string: %s\n", dataSource)
	db, err := sql.Open("postgres", dataSource)
	if err != nil {
		return nil, fmt.Errorf("couldn't connect to the postgres! %s", err.Error())
	}
	if err = db.Ping(); err != nil {
		return nil, fmt.Errorf("couldn't connect to the postgres! %s", err.Error())
	}

	q := New(db)

	return q, db.Ping()
}
