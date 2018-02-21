#!/bin/bash
set -e

# activate python2 environment
source activate python2

# only download workshop materials if default command has not been overridden
if [ $1 = "start-notebook.sh" ]; then
  if [ -n "$DEVELOP_REPOS" ]; then
    echo "Enabling python develop on: $DEVELOP_REPOS"
    for i in $DEVELOP_REPOS; do
      echo -e "/home/$NB_USER/$i/build/lib\n." > /opt/conda/envs/python2/lib/python2.7/site-packages/$i.egg-link
      echo "/home/$NB_USER/$i/build/lib"  >>  /opt/conda/envs/python2/lib/python2.7/site-packages/easy-install.pth
    done
    if [ $(id -u) == 0 ] ; then
      chown $NB_UID:$NB_GID /opt/conda/envs/python2/lib/python2.7/site-packages/*.egg-link /opt/conda/envs/python2/lib/python2.7/site-packages/*.pth
    fi
  fi
fi

exec "$@"
