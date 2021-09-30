package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"

	"oms-lite/app/handlers"
	omslitedb "oms-lite/business/sys/database"
	"oms-lite/docs"

	swaggerFiles "github.com/swaggo/files"     // swagger embed files
	ginSwagger "github.com/swaggo/gin-swagger" // gin-swagger middleware
)

// mustGetEnv is a helper function for getting environment variables.
// Displays a warning if the environment variable is not set.
func mustGetenv(key string) string {
	val, ok := os.LookupEnv(key)
	log.Println("Checking", key)
	if !ok {
		log.Fatalf("Warning: %s environment variable not set.\n", key)
	}
	return val
}

func checkEnvVar(key string) {
	val, ok := os.LookupEnv(key)
	if !ok {
		log.Fatalf("%s not set\n", key)
	}
	log.Printf("%s=%s\n", key, val)
}

var (
	dbUser                 = mustGetenv("POSTGRES_USER")            // e.g. 'my-db-user'
	dbPwd                  = mustGetenv("POSTGRES_PASSWORD")        // e.g. 'my-db-password'
	instanceConnectionName = mustGetenv("INSTANCE_CONNECTION_NAME") // e.g. 'project:region:instance'
	dbName                 = mustGetenv("POSTGRES_DB")              // e.g. 'my-database'
	dbHost                 = mustGetenv("POSTGRES_HOST")            // e.g. 'localhost'
)

// @title oms-lite API
// @version 1.0
// @description oms-lite API, you know

// @license.name Apache 2.0

// @BasePath /api/v1
func main() {

	// TODO: enable this check for local mode
	// checkEnvVar("GOOGLE_APPLICATION_CREDENTIALS")

	// Initialize connection string for local mode
	// var connectionString string = fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=%s",
	// 	mustGetenv("POSTGRES_HOST"), mustGetenv("POSTGRES_USER"), mustGetenv("POSTGRES_PASSWORD"), mustGetenv("POSTGRES_DB"), mustGetenv("POSTGRES_SSL_MODE"))

	// if not local mode
	socketDir, isSet := os.LookupEnv("DB_SOCKET_DIR")
	if !isSet {
		socketDir = "/cloudsql"
	}

	connectionString := fmt.Sprintf("%s:%s@unix(/%s/%s)/%s?parseTime=true", dbUser, dbPwd, socketDir, instanceConnectionName, dbName)

	// Use the InitDB function to open connection and get db object
	db, err := omslitedb.InitDB(connectionString)
	if err != nil {
		log.Fatal(err)
	}

	handlers := handlers.NewOrderHandler(db, otel.Tracer("oms-lite"))

	// init gin router
	r := gin.Default()

	// init tracing

	// tp := otel_tracer.InitTracer()
	// defer func() {
	// 	if err := tp.Shutdown(context.Background()); err != nil {
	// 		log.Printf("Error shutting down tracer provider: %v", err)
	// 	}
	// }()
	// r.Use(otelgin.Middleware("oms-lite"))

	docs.SwaggerInfo.BasePath = "/api/v1"
	r.GET("/", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/swagger/index.html")
	})
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

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

	srv := &http.Server{
		Addr:    ":8080",
		Handler: r,
	}

	// Initializing the server in a goroutine so that
	// it won't block the graceful shutdown handling below
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server with
	// a timeout of 5 seconds.
	quit := make(chan os.Signal, 1)
	// kill (no param) default send syscall.SIGTERM
	// kill -2 is syscall.SIGINT
	// kill -9 is syscall.SIGKILL but can't be catch, so don't need add it
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Received SIGINT/SIGTERM. Shutting down server...")

	// The context is used to inform the server it has 15 seconds to finish
	// the request it is currently handling
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown: ", err)
	}

	log.Println("Server exiting")
}
