package model

import "github.com/gofrs/uuid"

// OrderLine example
type OrderLine struct {
	UUID     uuid.UUID `json:"uuid" example:"3fa85f64-5717-4562-b3fc-2c963f66afa6" format:"uuid"`
	Product  Product   `json:"product"`
	Quantity uint64    `json:"quantity" example:"2"`
}
