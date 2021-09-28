package handlers

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"

	model "oms-lite/business"
)

var Tracer = otel.Tracer("oms-lite")

func GetOrderById(c *gin.Context, id string) (string, error) {

	if id == "123" {
		return "otelgin tester", nil
	}
	return "", errors.New("not found")
}

func ListOrders(c *gin.Context) (string, error) {
	return "all orders", nil
}

func DeleteOrderById(c *gin.Context, id string) (string, error) {

	if id == "123" {
		return "deleted!", nil
	}
	return "", errors.New("not found")
}

// @BasePath /api/v1
// @Summary list all orders
// @Schemes
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {array} model.Order
// @Router /orders [get]
func ListOrdersHandler(c *gin.Context) {
	_, span := Tracer.Start(c.Request.Context(), "ListOrders")
	defer span.End()

	name, err := ListOrders(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"name": name,
	})
}

// @BasePath /api/v1
// @Summary get order by id
// @Schemes
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {object} model.Order
// @Param order_id path string true "Order ID"
// @Router /orders/{order_id} [get]
func GetOrderHandler(c *gin.Context) {
	id := c.Param("id")
	_, span := Tracer.Start(c.Request.Context(), "GetOrderById", oteltrace.WithAttributes(attribute.String("id", id)))
	defer span.End()

	name, err := GetOrderById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"name": name,
		"id":   id,
	})
}

// @BasePath /api/v1
// @Summary delete order by id
// @Schemes
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {object} model.Order
// @Param order_id path string true "Order ID"
// @Router /orders/{order_id} [delete]
func DeleteOrderHandler(c *gin.Context) {
	id := c.Param("id")
	_, span := Tracer.Start(c.Request.Context(), "DeleteOrderById", oteltrace.WithAttributes(attribute.String("id", id)))
	defer span.End()

	name, err := DeleteOrderById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"name": name,
		"id":   id,
	})
}

// @BasePath /api/v1
// @Summary create new order
// @Schemes
// @Tags orders
// @Accept json
// @Produce json
// @Param order_lines body []model.OrderLine true "OrderLines to placed in the new order"
// @Success 200 {object} model.Order
// @Router /orders/ [post]
func CreateOrderHandler(c *gin.Context) {
	_, span := Tracer.Start(c.Request.Context(), "CreateOrderHandler")
	defer span.End()

	var json []model.OrderLine

	if err := c.ShouldBindJSON(&json); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	order, err := model.CreateOrder(c, json)
	log.Printf("%+v", order)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"order":  order,
	})
}
