#!/bin/bash
set -e

# activate python2 environment
source activate python2

exec "$@"
