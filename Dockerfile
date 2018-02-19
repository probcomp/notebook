# jupyter project recommends pinning the base image: https://github.com/jupyter/docker-stacks#other-tips-and-known-issues
FROM jupyter/scipy-notebook:9faed6a154bb

# install fonts used in some tutorials/tests. also, a couple random packages that are nice for dev environment.
USER root
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
    | debconf-set-selections && \
    apt-get -qy update && apt-get install -qy apt-transport-https htop less ttf-mscorefonts-installer && \
    rm -rf /var/lib/apt/list/* /tmp/* /var/tmp/* /var/cache/apt/*

USER $NB_USER
COPY files/*.txt /tmp/

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

# add custom css/logo and tutorials
COPY files/custom/ /home/$NB_USER/.jupyter/custom/
COPY tutorials/ /home/$NB_USER/tutorials/

# need to run this here so the fix-permissions script succeeds later
RUN chown -R $NB_USER $CONDA_DIR/var/cache/fontconfig && \
    chown -R $NB_USER /home/$NB_USER

USER $NB_USER

# bash improvements for developer environment
RUN git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it && \
    bash ~/.bash_it/install.sh --silent && \
    echo "source activate python2\nalias pytest=py.test\nexport SCM_CHECK=false" >> /home/$NB_USER/.bashrc

# install the probcomp libraries, fix permissions
RUN conda install -n python2 --quiet --yes -c probcomp -c cidermole -c fritzo -c ursusest \
    --file /tmp/conda_probcomp.txt && \
    conda remove -n python2 --quiet --yes --force qt pyqt && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Add local files as late as possible to avoid cache busting
COPY files/docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT      ["tini", "--", "docker-entrypoint.sh"]
CMD             ["start-notebook.sh"]
