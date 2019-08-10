#!/bin/bash
set -e

# start julia with threads=cores
export JULIA_NUM_THREADS=$(nproc)

# only initialize if default command has not been overridden
if [ $1 = "start-notebook.sh" ]; then
  if [ -n "$DEVELOP_REPOS" ]; then
    echo "Enabling develop on: $DEVELOP_REPOS"
    for repo in $DEVELOP_REPOS; do
      echo "  Uninstalling $repo conda package"
      conda uninstall -n python2 --quiet --yes $repo >/dev/null 2>&1
      echo "  Creating $repo.egg-link"
      echo "/home/$NB_USER/$repo/build/lib"                   > /opt/conda/envs/python2/lib/python2.7/site-packages/$repo.egg-link
      echo "/home/$NB_USER/$repo/build/lib.linux-x86_64-2.7" >> /opt/conda/envs/python2/lib/python2.7/site-packages/$repo.egg-link
      echo "."                                               >> /opt/conda/envs/python2/lib/python2.7/site-packages/$repo.egg-link
      echo "/home/$NB_USER/$repo/build/lib"                  >> /opt/conda/envs/python2/lib/python2.7/site-packages/easy-install.pth
      echo "/home/$NB_USER/$repo/build/lib.linux-x86_64-2.7" >> /opt/conda/envs/python2/lib/python2.7/site-packages/easy-install.pth
      echo "  Building $repo"
      bash -c "cd /home/$NB_USER/$repo && rm -rf build && python setup.py build" >/dev/null 2>&1
      if [ $(id -u) == 0 ] ; then
        chown -R $NB_UID /home/$NB_USER/$repo /opt/conda/envs/python2/lib/python2.7/site-packages/*.egg-link /opt/conda/envs/python2/lib/python2.7/site-packages/*.pth /opt/conda/pkgs/cache
      fi
    done
  fi

  # for installing julia packages when running the developer environment
  if [ $(id -u) == 0 ] ; then
    echo "Running chown -R ${NB_UID} /opt/julia (this will take a while)..."
    chown -R $NB_UID /opt/julia
  fi
  # add the logo, etc.
  rsync -aq /usr/local/etc/skel/jupyter/.jupyter/custom /home/$NB_USER/.jupyter/
  # rsync tutorials from skeleton directory unless $SKIP_TUTORIAL_SYNC is set
  if [[ "$SKIP_TUTORIAL_SYNC" == "1" || "$SKIP_TUTORIAL_SYNC" == 'yes' ]]; then
    echo "Skipping tutorial notebook sync"
  else
    echo "Syncing tutorial notebooks"
    rsync -aq /usr/local/etc/skel/jupyter/tutorials /home/$NB_USER/
  fi
  echo "Trusting tutorial notebooks"
  if [ $(id -u) == 0 ] ; then
    sudo -u $NB_USER -E /opt/conda/bin/jupyter-trust /home/$NB_USER/tutorials/*.ipynb >/dev/null
    chown -R $NB_UID /home/$NB_USER/.local
  else
    /opt/conda/bin/jupyter-trust /home/$NB_USER/tutorials/*.ipynb >/dev/null
  fi
fi

exec "$@"
