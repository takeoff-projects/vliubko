package main

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"oms-lite/app/handlers"
	"oms-lite/docs"
	otel_tracer "oms-lite/foundation"

	swaggerFiles "github.com/swaggo/files"     // swagger embed files
	ginSwagger "github.com/swaggo/gin-swagger" // gin-swagger middleware
)

// @title oms-lite API
// @version 1.0
// @description oms-lite API, you know

// @license.name Apache 2.0

// @host localhost:8080
// @BasePath /api/v1

func main() {
	tp := otel_tracer.InitTracer()
	defer func() {
		if err := tp.Shutdown(context.Background()); err != nil {
			log.Printf("Error shutting down tracer provider: %v", err)
		}
	}()

	r := gin.Default()
	// r.Use(otelgin.Middleware("oms-lite"))
	docs.SwaggerInfo.BasePath = "/api/v1"

	api := r.Group("/api")
	{
		v1 := api.Group("/v1")
		{
			orders := v1.Group("/orders")
			{
				orders.GET("", handlers.ListOrdersHandler)
				orders.GET(":id", handlers.GetOrderHandler)
				orders.POST("", handlers.CreateOrderHandler)
				orders.DELETE(":id", handlers.DeleteOrderHandler)
			}
		}
	}

	r.GET("/", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/swagger/index.html")
	})
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	_ = r.Run(":8080")
}
