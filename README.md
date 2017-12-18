# Overview

jupyter/scipy-notebook with MIT ProbComp libraries. See the docs here: https://hub.docker.com/r/jupyter/scipy-notebook/

Note that probcomp notebook runs in a python 2.x environment so documentation related to python 3 may not work in this image.

# Running the image:
```
docker run -it --rm -p 8888:8888 probcomp/notebook
```

or use the included docker-compose file:

```
docker-compose up
```
