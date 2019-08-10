## Overview

[jupyter/datascience-notebook](https://hub.docker.com/r/jupyter/datascience-notebook/) with
[MIT Probabilistic Computing Project](http://probcomp.org/) libraries. See the
[jupyter/datascience-notebook](https://hub.docker.com/r/jupyter/datascience-notebook/)
repo's documentaiton for various runtime options.

## Quickstart:

__Method 1__: Using the Makefile

After cloning the repo, you can make use of the following directives:

* `make up` -- start the notebook
* `make down` -- stop the notebook
* `make bash` -- start a bash shell
* `make ipython` -- start an ipython2 shell with access to probcomp python2 libraries
* `make ipython3` -- start an ipython3 shell with access to the default `jupyter/datascience-notebook` python3 libraries
* `make julia` -- start a julia shell

__Method 2__: Using docker directly

Or run the image directly:

```
$ docker run -it --rm -p 8888:8888 probcomp/notebook
```
