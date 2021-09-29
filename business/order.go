package model

import (
	"errors"
	omslitedb "oms-lite/business/sys/database"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
)

var Tracer = otel.Tracer("oms-lite")

func CreateOrder(c *gin.Context, db *omslitedb.Queries, order omslitedb.CreateOrderParams) (int64, error) {
	_, span := Tracer.Start(c.Request.Context(), "CreateOrderInDB")
	defer span.End()

	if order.Quantity <= 0 {
		return 0, errors.New("quantity should be more than 0")
	}

	orderID, err := db.CreateOrder(c, order)
	if err != nil {
		return 0, err
	}
	return orderID, err
}

func DeleteOrderByID(c *gin.Context, db *omslitedb.Queries, id int64) error {
	_, span := Tracer.Start(c.Request.Context(), "DeleteOrderByIDInDB")
	defer span.End()

	err := db.DeleteOrder(c, id)
	if err != nil {
		return err
	}
	return nil
}

func GetOrderByID(c *gin.Context, db *omslitedb.Queries, id int64) (omslitedb.Order, error) {
	_, span := Tracer.Start(c.Request.Context(), "GetOrderByIDInDB")
	defer span.End()

	order, err := db.GetOrder(c, id)
	if err != nil {
		return omslitedb.Order{}, err
	}
	return order, nil
}

func ListOrders(c *gin.Context, db *omslitedb.Queries) ([]omslitedb.Order, error) {
	_, span := Tracer.Start(c.Request.Context(), "ListOrdersInDB")
	defer span.End()

	orders, err := db.ListOrders(c)
	if err != nil {
		return []omslitedb.Order{}, err
	}
	return orders, nil
}
