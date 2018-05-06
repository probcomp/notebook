#!/bin/bash
set -e

curl -H "Content-Type: application/json" --data '{"docker_tag": "edge"}' -X POST https://registry.hub.docker.com/u/probcomp/notebook/trigger/${DOCKER_HUB_TOKEN}/
