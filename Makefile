current_dir = $(shell pwd)

local:
	docker run --rm --name static_website -it --volume ${current_dir}/public:/usr/share/nginx/html/ -p 8080:80  nginx:1.21.3
