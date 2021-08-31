export TAG=v1.1.0

docker/Dockerfile.php: docker/source/Dockerfile.php.in docker/source/*.docker
	cd docker && make Dockerfile.php

start: docker/Dockerfile.php
	docker-compose -f docker-compose.yml start

stop: docker/Dockerfile.php
	docker-compose -f docker-compose.yml stop

up: docker/Dockerfile.php
	docker-compose -f docker-compose.yml up -d

upNoDaemon: docker/Dockerfile.php
	docker-compose -f docker-compose.yml up

upBuild: docker/Dockerfile.php
	docker-compose -f docker-compose.yml up --build -d

upBuildNoDaemon: docker/Dockerfile.php
	docker-compose -f docker-compose.yml up --build

build: docker/Dockerfile.php
	docker-compose build

enter: run
run:
	docker run -v bobash-rc:/bobash/home -u developer -it bobash bash -c 'HOME=/bobash/home bash'

logs:
	docker logs -f bobash
