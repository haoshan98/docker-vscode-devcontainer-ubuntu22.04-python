# Refer to https://github.com/matthewfeickert/Docker-Python3-Ubuntu
FROM ubuntu:22.04 

USER root
WORKDIR /root

SHELL [ "/bin/bash", "-c" ]

ARG PYTHON_VERSION_TAG=3.9.18
ARG LINK_PYTHON_TO_PYTHON3=1

# Existing lsb_release causes issues with modern installations of Python3
# https://github.com/pypa/pip/issues/4924#issuecomment-435825490
# Set (temporarily) DEBIAN_FRONTEND to avoid interacting with tzdata
RUN apt-get -qq -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq -y install \
        gcc \
        g++ \
        # zlibc \
        zlib1g-dev \
        libssl-dev \
        libbz2-dev \
        libsqlite3-dev \
        libncurses5-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        liblzma-dev \
        libreadline-dev \
        uuid-dev \
        libffi-dev \
        tk-dev \
        wget \
        curl \
        git \
        make \
        sudo \
        bash-completion \
        tree \
        vim \
        software-properties-common && \
    mv /usr/bin/lsb_release /usr/bin/lsb_release.bak && \
    apt-get -y autoclean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

COPY install_python.sh install_python.sh
RUN bash install_python.sh ${PYTHON_VERSION_TAG} ${LINK_PYTHON_TO_PYTHON3} && \
    rm -r install_python.sh Python-${PYTHON_VERSION_TAG}

# Enable tab completion by uncommenting it from /etc/bash.bashrc
# The relevant lines are those below the phrase "enable bash completion in interactive shells"
RUN export SED_RANGE="$(($(sed -n '\|enable bash completion in interactive shells|=' /etc/bash.bashrc)+1)),$(($(sed -n '\|enable bash completion in interactive shells|=' /etc/bash.bashrc)+7))" && \
    sed -i -e "${SED_RANGE}"' s/^#//' /etc/bash.bashrc && \
    unset SED_RANGE



ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
### Mount Point ###
# When launching the container, mount the code directory to /app
ARG APP_MOUNT=/app
VOLUME [ ${APP_MOUNT} ]
WORKDIR ${APP_MOUNT}

# RUN pip3 install torchvision torchaudio torch --index-url https://download.pytorch.org/whl/cu118
COPY ./requirements.txt /requirements.txt
RUN python3 -m pip install --no-cache-dir -r /requirements.txt

### Create a non-root user ###
# https://github.com/facebookresearch/detectron2/blob/v0.3/docker/Dockerfile
# https://code.visualstudio.com/docs/remote/containers-advanced#_creating-a-nonroot-user
ARG USER=appuser
ARG UID=1000
ARG GID=1000
RUN useradd -m --no-log-init --system  --uid ${UID} ${USER} -g sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV PATH=/home/${USER}/.local/bin:${PATH}
RUN chown -R ${UID}:${GID} /home/${USER} \
    && chown -R ${UID}:${GID} /usr/local/lib/python* \
    && chown -R ${UID}:${GID} /usr/lib/python*
USER ${USER}
ENTRYPOINT []