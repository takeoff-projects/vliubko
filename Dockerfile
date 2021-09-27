# builder image
FROM golang:1.16-buster AS builder
WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -a -o go-website .


# generate clean, final image for end users
FROM gcr.io/distroless/base-debian10
COPY --from=builder /build/go-website .

USER nonroot:nonroot

# executable
ENTRYPOINT [ "./go-website" ]
# arguments that can be overridden
# CMD [ "3", "300" ]
