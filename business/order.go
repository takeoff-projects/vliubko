package model

import (
	"github.com/gin-gonic/gin"
	"github.com/gofrs/uuid"
)

// Order example
type Order struct {
	UUID       uuid.UUID   `json:"uuid" example:"550e8400-e29b-41d4-a716-446655440000" format:"uuid"`
	OrderLines []OrderLine `json:"order_lines"`
}

// We don't check if product exists, we except this check somewhere else (in Products service?)
func CreateOrder(c *gin.Context, orderLines []OrderLine) (Order, error) {
	OrderUuid, err := uuid.NewV4()
	if err != nil {
		return Order{}, err
	}

	for k := range orderLines {
		olUuid, err := uuid.NewV4()
		if err != nil {
			return Order{}, err
		}
		orderLines[k].UUID = olUuid
	}

	order := Order{
		UUID:       OrderUuid,
		OrderLines: orderLines,
	}
	return order, nil
}
