#!/bin/bash
set -e

# activate python2 environment
source activate python2

#cp -r /branding ~/.jupyter/custom
if [ ! -f ~/work/satellites-predictive.ipynb ]; then
  mkdir -p ~/tmp
  cd ~/tmp && wget --progress=dot:giga -O - https://${CONTENT_URL} | gunzip -c | tar xf -
  mv ~/tmp/notebook/* ~/work/
  rm -r ~/tmp
fi

cd ~
exec "$@"
