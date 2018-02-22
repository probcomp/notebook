#!/bin/bash
set -e

# activate python2 environment
source activate python2

# only download workshop materials if default command has not been overridden
if [ $1 = "start-notebook.sh" ]; then
  if [ -n "$DEVELOP_REPOS" ]; then
    echo "Enabling develop on: $DEVELOP_REPOS"
    for repo in $DEVELOP_REPOS; do
      echo "  Creating $repo.egg-link"
      echo -e "/home/$NB_USER/$repo/build/lib\n." > /opt/conda/envs/python2/lib/python2.7/site-packages/$repo.egg-link
      echo "/home/$NB_USER/$repo/build/lib"  >>  /opt/conda/envs/python2/lib/python2.7/site-packages/easy-install.pth
      echo "  Uninstalling $repo conda package"
      conda uninstall --quiet --yes $repo >/dev/null 2>&1
      echo "  Building $repo"
      bash -c "cd /home/$NB_USER/$repo && rm -rf build && python setup.py build" >/dev/null 2>&1
      if [ $(id -u) == 0 ] ; then
        chown -R $NB_UID /home/$NB_USER/$repo /opt/conda/envs/python2/lib/python2.7/site-packages/*.egg-link /opt/conda/envs/python2/lib/python2.7/site-packages/*.pth
      fi
    done
  fi
fi

exec "$@"
