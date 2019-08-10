## Overview

[jupyter/datascience-notebook](https://hub.docker.com/r/jupyter/datascience-notebook/) with
[MIT Probabilistic Computing Project](http://probcomp.org/) libraries. See the
[jupyter/datascience-notebook](https://hub.docker.com/r/jupyter/datascience-notebook/)
repo's documentation for various runtime options.

## Quickstart:

__Method 1__: Using the Makefile

After cloning the repo, you can make use of the following directives:

* `make up` -- start the notebook
* `make down` -- stop the notebook
* `make pull` -- pull the latest version of the image (try this first if you're having any issues)
* `make bash` -- start a bash shell
* `make ipython` -- start an ipython2 shell with access to probcomp python2 libraries
* `make ipython3` -- start an ipython3 shell with access to the default `jupyter/datascience-notebook` python3 libraries
* `make julia` -- start a julia shell

__Method 2__: Using docker directly

Or run the image directly:

```
$ docker run -it --rm -p 8888:8888 probcomp/notebook
```

## Docker Tips

### Make additional host directories available inside the container

To make additional host directories available from inside the container, first `cp docker-compose.override.yml.example docker-compose.override.yml` and then add additional entries to the YAML list in `docker-compose.override.yml` at the keypath `services` `notebook` `volumes`. For more information see the [official Docker documentation for the `volumes` key](https://docs.docker.com/compose/compose-file/#volumes).

### Increasing D4M Resources

The default D4M resource limits are too low for the jupyter notebook. It's recommended that you allocate at least 8GB of RAM and all CPU cores to D4M. Any unused resources will still be available to OSX.

<img src="https://github.com/probcomp/notebook/blob/master/files/resources.png" width="250">

If you have sufficient system resources, allocate 32GB of RAM to D4M for optimal notebook performance.

<img src="https://github.com/probcomp/notebook/blob/master/files/resources_high.png" width="250">

### Pruning Images and Resources

Run `docker system prune` to clean up your docker environment. You'll need to run this periodically as your D4M virtual machine or Linux system gets low on disk space. Otherwise, the environment may fail to start or you may see strange behavior (e.g. processes unexpectedly exiting).
