include .env
export $(shell sed 's/=.*//' .env)

current_dir = $(shell pwd)
GOMODCACHE = $(shell go env GOMODCACHE)

UI_PORT=9090

.PHONY : run-ui run-api swagger gen-sql migrate-up migrate-down

run-ui:
	docker run --rm --name static_website -it --volume ${current_dir}/public:/usr/share/nginx/html/ -p ${UI_PORT}:80  nginx:1.21.3

run-api:
	export GOMODCACHE=${GOMODCACHE} && docker compose up

swagger:
	swag init -d app --parseInternal --parseDependency --parseDepth 2

gen-sql:
	sqlc generate -f db/sqlc.yaml

migrate-up:
	export POSTGRES_HOST=localhost;\
	migrate -database "postgres://$$POSTGRES_USER:${POSTGRES_PASSWORD}@$$POSTGRES_HOST:5432/${POSTGRES_DB}?sslmode=disable" -path db/migrations up

migrate-down:
	export POSTGRES_HOST=localhost;\
	migrate -database "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode=disable" -path db/migrations down -f

migrate-up-cloud-sql:
	migrate -database "postgres://$$POSTGRES_USER:${POSTGRES_PASSWORD}@$$POSTGRES_HOST:5432/${POSTGRES_DB}?sslmode=disable" -path db/migrations up

migrate-down-cloud-sql:
	migrate -database "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@$$POSTGRES_HOST:5432/${POSTGRES_DB}?sslmode=disable" -path db/migrations down
