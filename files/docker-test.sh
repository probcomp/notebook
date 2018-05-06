#!/bin/bash
set -Ceux

# Build the image.
image=probcomp/jenkins/"${JOB_NAME}":"${BUILD_NUMBER}"
container=probcomp-jenkins-"${JOB_NAME}"-"${BUILD_NUMBER}"

# Run the tests.
docker run --rm \
    --name "${container}" \
    "${image}" \
    sh -c 'cd tutorials && python -m pytest ${1+"$@"}' -- ${1+"$@"}
