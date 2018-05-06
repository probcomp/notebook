#!/bin/bash
set -Ceux

# Build the image.
image=probcomp/jenkins/"${JOB_NAME}":"${BUILD_NUMBER}"
container=probcomp-jenkins-"${JOB_NAME}"-"${BUILD_NUMBER}"
docker build --no-cache -t "probcomp/notebook" .
docker build --no-cache -t "${image}" -f Dockerfile-edge .
