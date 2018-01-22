## Overview

[jupyter/scipy-notebook](https://hub.docker.com/r/jupyter/scipy-notebook/) with [MIT Probabilistic Computing Project](http://probcomp.org/) libraries. See the [jupyter/scipy-notebook](https://hub.docker.com/r/jupyter/scipy-notebook/) repo's documentaiton for various runtime options.

## Quickstart:

__Method 1__: Using docker-compose

The easiest method to run the image for end-user consumption is with the included [docker-compose file](https://github.com/probcomp/notebook/blob/master/docker-compose.yml):

```
$ wget https://raw.githubusercontent.com/probcomp/notebook/master/docker-compose.yml
$ docker-compose up
```

__Method 2__: Using docker directly.

Or run the image directly:
```
$ docker run -it --rm -p 8888:8888 probcomp/notebook
```

Alternately, you can run an ipython shell:
```
$ docker run -it --rm probcomp/notebook start.sh ipython
```
