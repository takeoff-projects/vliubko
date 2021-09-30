package oteltracer

import (
	"log"

	gcp_trace_exporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"go.opentelemetry.io/otel"
	stdout_trace_exporter "go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/propagation"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

func InitTracer() *sdktrace.TracerProvider {
	// projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")

	gcpTraceExporter, err := gcp_trace_exporter.New()
	if err != nil {
		log.Fatal(err)
	}
	stdoutTraceExporter, err := stdout_trace_exporter.New()
	if err != nil {
		log.Fatal(err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithBatcher(gcpTraceExporter),
		sdktrace.WithBatcher(stdoutTraceExporter),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	return tp
}
