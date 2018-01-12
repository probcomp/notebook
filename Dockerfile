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
    'eigen=3.3.*' \
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

# add custom css/logo
COPY custom/ /home/$NB_USER/.jupyter/custom/
RUN  chown -R $NB_USER:users /home/$NB_USER/.jupyter

USER $NB_USER

# install the probcomp libraries
RUN conda install -n python2 --quiet --yes -c probcomp -c cidermole -c fritzo -c ursusest \
    'apsw' \
    'bayeslite=0.3.2' \
    'cgpm=0.1.2' \
    'crosscat=0.1.56.1' \
    'distributions=2.2.1' \
    'libprotobuf=2.6.1' \
    'loom=0.2.10' \
    'iventure=0.2.2' \
    'venture=0.5.1.1'

# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN conda remove -n python2 --quiet --yes --force qt pyqt && \
    conda clean -tipsy

ENV CONTENT_URL probcomp-workshop-materials.s3.amazonaws.com/latest.tgz
COPY docker-entrypoint.sh /usr/bin

ENTRYPOINT      ["docker-entrypoint.sh"]
CMD             ["start-notebook.sh"]
