#!/usr/bin/env bash

docker run \
	-it \
	-v ~/bobash-test:/bobash/home \
	bobash \
	bash -c 'HOME=/bobash/home bash'

