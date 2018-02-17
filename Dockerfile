# jupyter project recommends pinning the base image: https://github.com/jupyter/docker-stacks#other-tips-and-known-issues
FROM jupyter/scipy-notebook:9faed6a154bb

COPY files/*.txt /tmp/
COPY tutorials/ /home/$NB_USER/tutorials/

# jupyter project recently removed support for python2, we'll recreate it using their commit as a guide
# https://github.com/jupyter/docker-stacks/commit/32b3d2bec23bc46fab1ed324f04a0ad7a7c73747#commitcomment-24129620

# Install Python 2 packages
RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
    --file /tmp/conda_python2.txt
# Add shortcuts to distinguish pip for python2 and python3 envs
RUN ln -s $CONDA_DIR/envs/python2/bin/pip $CONDA_DIR/bin/pip2 && \
    ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
ENV MPLBACKEND=Agg
RUN $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

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
COPY files/custom/ /home/$NB_USER/.jupyter/custom/
RUN  chown -R $NB_USER:users /home/$NB_USER && \
     chmod 666 /tmp/*.txt

USER $NB_USER

# install the probcomp libraries
RUN conda install -n python2 --quiet --yes -c probcomp -c cidermole -c fritzo -c ursusest \
    --file /tmp/conda_probcomp.txt && \
    conda remove -n python2 --quiet --yes --force qt pyqt && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN echo "source activate python2\nalias pytest=py.test" >> /home/$NB_USER/.bashrc

# Add local files as late as possible to avoid cache busting
COPY files/docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT      ["tini", "--", "docker-entrypoint.sh"]
CMD             ["start-notebook.sh"]
