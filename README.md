# Overview

[jupyter/scipy-notebook](https://hub.docker.com/r/jupyter/scipy-notebook/) with [MIT Probabilistic Computing Project](http://probcomp.org/) libraries. See the [jupyter/scipy-notebook](https://hub.docker.com/r/jupyter/scipy-notebook/) repo's documentaiton for various runtime options.

# Quickstart:

## docker-compose

The easiest method to run the image for end-user consumption is with the included [docker-compose file](https://github.com/probcomp/notebook/blob/master/docker-compose.yml):

```
wget https://raw.githubusercontent.com/probcomp/notebook/master/docker-compose.yml && docker-compose up
```

## docker

Or run the image directly:
```
docker run -it --rm -p 8888:8888 probcomp/notebook
```

Alternately, you can run an ipython shell:
```
docker run -it --rm probcomp/notebook start.sh ipython
```

# Further Reading

See [Richard Tibbetts's talk at Strange Loop](https://www.youtube.com/watch?v=7_m7JCLKmTY) for a walkthrough of the example satellite dataset included in this image.
