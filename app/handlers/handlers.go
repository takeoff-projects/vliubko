package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"

	model "oms-lite/business"
	omslitedb "oms-lite/business/sys/database"
)

type JSONResult struct {
	Status string `json:"status" `
}

// used by Swagger docs
var ok = JSONResult{Status: "ok"}

// OrderHandler will hold everything that controller needs
type OrderHandler struct {
	Db     *omslitedb.Queries
	Tracer oteltrace.Tracer
}

// NewOrderHandler returns a new OrderHandler
func NewOrderHandler(db *omslitedb.Queries, tracer oteltrace.Tracer) *OrderHandler {
	return &OrderHandler{
		Db:     db,
		Tracer: tracer,
	}
}

// @BasePath /api/v1
// @Summary list all orders
// @Schemes
// @Id list_all_orders
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {object} JSONResult{orders=[]omslitedb.Order}
// @Router /orders [get]
func (h *OrderHandler) ListOrdersHandler(c *gin.Context) {
	_, span := h.Tracer.Start(c.Request.Context(), "ListOrders")
	defer span.End()

	orders, err := model.ListOrders(c, h.Db)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"orders": orders,
	})
}

// @BasePath /api/v1
// @Summary get order by id
// @Schemes
// @Id get_order_by_id
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {object} JSONResult{order=omslitedb.Order}
// @Param order_id path string true "Order ID"
// @Router /orders/{order_id} [get]
func (h *OrderHandler) GetOrderHandler(c *gin.Context) {
	id_string := c.Param("id")

	id, err := strconv.ParseInt(id_string, 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}

	_, span := h.Tracer.Start(c.Request.Context(), "GetOrderById", oteltrace.WithAttributes(attribute.Int64("id", id)))
	defer span.End()

	order, err := model.GetOrderByID(c, h.Db, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"order":  order,
	})
}

// @BasePath /api/v1
// @Summary delete order by id
// @Schemes
// @Id delete_order_by_id
// @Tags orders
// @Accept json
// @Produce json
// @Success 200 {object} JSONResult
// @Param order_id path string true "Order ID"
// @Router /orders/{order_id} [delete]
func (h *OrderHandler) DeleteOrderHandler(c *gin.Context) {
	id := c.GetInt64("id")
	_, span := h.Tracer.Start(c.Request.Context(), "DeleteOrderById", oteltrace.WithAttributes(attribute.Int64("id", id)))
	defer span.End()

	if err := model.DeleteOrderByID(c, h.Db, id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "fail",
			"error":  err,
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
	})
}

// @BasePath /api/v1
// @Summary create new order
// @Schemes
// @Id create_order
// @Tags orders
// @Accept json
// @Produce json
// @Param order body omslitedb.CreateOrderParams true "Create order with product&quantity"
// @Success 200 {object} JSONResult{orderID=int64}
// @Router /orders/ [post]
func (h *OrderHandler) CreateOrderHandler(c *gin.Context) {
	_, span := h.Tracer.Start(c.Request.Context(), "CreateOrderHandler")
	defer span.End()

	var Order omslitedb.CreateOrderParams

	if err := c.ShouldBindJSON(&Order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	orderID, err := model.CreateOrder(c, h.Db, Order)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "fail",
			"error":  err,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"orderID": orderID,
	})
}
