# jupyter project recommends pinning the base image: https://github.com/jupyter/docker-stacks#other-tips-and-known-issues
FROM jupyter/scipy-notebook:da2c5a4d00fa

# jupyter project recently removed support for python2, we'll recreate it using their commit as a guide
# https://github.com/jupyter/docker-stacks/commit/32b3d2bec23bc46fab1ed324f04a0ad7a7c73747#commitcomment-24129620

# Install Python 2 packages
RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
    'beautifulsoup4=4.5.*' \
    'bokeh=0.12*' \
    'cloudpickle=0.2*' \
    'cython=0.25*' \
    'dill=0.2*' \
    'h5py=2.7*' \
    'hdf5=1.10.1' \
    'ipython=5.3*' \
    'ipywidgets=6.0*' \
    'matplotlib=1.5.*' \
    'nomkl' \
    'numba=0.31*' \
    'numexpr=2.6*' \
    'numpy=1.11.*' \
    'pandas=0.18.*' \
    'patsy=0.4*' \
    'pyflakes' \
    'pyzmq' \
    'scikit-image=0.12*' \
    'scikit-learn=0.17.*' \
    'scipy=0.17.*' \
    'seaborn=0.7.*' \
    'six=1.10.*' \
    'sqlalchemy=1.1*' \
    'statsmodels=0.6.*' \
    'sympy=1.0*' \
    'vincent=0.4.*' \
    'xlrd'
# Add shortcuts to distinguish pip for python2 and python3 envs
RUN ln -s $CONDA_DIR/envs/python2/bin/pip $CONDA_DIR/bin/pip2 && \
    ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

USER root

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime and to allow the notebook server running out of the root
# environment to find it. Also, activate the python2 environment upon kernel
# launch.
RUN pip install kernda --no-cache && \
    $CONDA_DIR/envs/python2/bin/python -m ipykernel install && \
    kernda -o -y /usr/local/share/jupyter/kernels/python2/kernel.json && \
    pip uninstall kernda -y

# install loom apt dependencies
RUN apt-get update -qq \
    && apt-get install -qq -y \
    cmake \
    libboost-python-dev \
    libeigen3-dev \
    libgoogle-perftools-dev \
    python-software-properties \
    software-properties-common

RUN add-apt-repository ppa:maarten-fonville/protobuf \
    && apt-get update -qq \
    && apt-get install -qq -y \
    libprotobuf-dev \
    protobuf-compiler

USER $NB_USER

# install the probcomp libraries
RUN conda install -n python2 --quiet --yes -c probcomp \
    'apsw' \
    'bayeslite=0.3.1.1' \
    'cgpm=0.1.1' \
    'crosscat=0.1.56.1' \
    'iventure=0.2.1' \
    'venture=0.5.1.1'

# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN conda remove -n python2 --quiet --yes --force qt pyqt && \
    conda clean -tipsy

# install loom
ENV DISTRIBUTIONS_USE_PROTOBUF=1
RUN mkdir deps \
    && cd deps \
    && git clone https://github.com/posterior/distributions.git \
    && git clone https://github.com/posterior/loom.git

##RUN bash -c "source activate python2 \
##    && pip install -I cpplint \
##    && cd $HOME/deps/distributions \
##    && make install \
##    && cd $HOME/deps/loom \
##    && make install"

ENV CONTENT_URL probcomp-oreilly20170627.s3.amazonaws.com/content-package.tgz
COPY docker-entrypoint.sh /usr/bin

ENTRYPOINT      ["docker-entrypoint.sh"]
CMD             ["start-notebook.sh"]
