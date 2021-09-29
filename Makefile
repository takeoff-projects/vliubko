current_dir = $(shell pwd)
GOMODCACHE = $(shell go env GOMODCACHE)

local:
	docker run --rm --name static_website -it --volume ${current_dir}/public:/usr/share/nginx/html/ -p 8080:80  nginx:1.21.3

compose:
	export GOMODCACHE=${GOMODCACHE} && docker compose up

swagger:
	swag init -d app --parseInternal --parseDependency --parseDepth 2

gen-sql:
	sqlc generate -f db/sqlc.yaml

migrate:
	migrate -database ${POSTGRESQL_URL} -path db/migrations up