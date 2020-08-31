# DeepFaceLab Dockerfile for Anaconda with TensorFlow stack
# Copyright (C) 2020  Chelsea E. Manning
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM xychelsea/tensorflow:latest
LABEL description="DeepFaceLab Vanilla Container"

# $ docker build -t xychelsea/deepfacelab:latest -f Dockerfile .
# $ docker run --rm -it xychelsea/deepfacelab:latest /bin/bash
# $ docker push xychelsea/deepfacelab:latest

ENV ANACONDA_ENV=deepfacelab
ENV DEEPFACELAB_PATH=/usr/local/deepfacelab
ENV DEEPFACELAB_HOME=${HOME}/deepfacelab
ENV DEEPFACELAB_WORKSPACE=${DEEPFACELAB_PATH}/workspace
ENV DEEPFACELAB_SCRIPTS=${DEEPFACELAB_PATH}/scripts

# Start as root
USER root

# Update packages
RUN apt-get update --fix-missing \
    && apt-get -y upgrade \
    && apt-get -y dist-upgrade

# Install dependencies
RUN apt-get -y install \
    git \
    libglu1-mesa-dev

# Create DeepFaceLab directory
RUN mkdir -p ${DEEPFACELAB_PATH} \
    && fix-permissions ${DEEPFACELAB_PATH}

# Switch to user "anaconda"
USER ${ANACONDA_UID}
WORKDIR ${HOME}

# Update Anaconda
RUN conda update -c defaults conda

# Install DeepFaceLab
RUN conda create -n deepfacelab -c main python=3.6.8 \
    && conda install -c conda-forge -n deepfacelab \
        colorama \
        h5py==2.9.0 \
        ffmpeg \
        numpy==1.17.0 \
        pyqt \
        scikit-image==0.14.2 \
        scipy==1.4.1 \
        tqdm \
    && PATH=${ANACONDA_PATH}/envs/${ANACONDA_ENV}/bin/:$PATH \
    && pip3 install \
        labelme==4.2.9 \
        ffmpeg-python==0.1.17 \
        opencv-python==4.1.0.25 \
        tensorflow==1.13.2 \
    && git clone git://github.com/iperov/DeepFaceLab.git ${DEEPFACELAB_PATH} \
    && git clone git://github.com/nagadit/DeepFaceLab_Linux.git ${DEEPFACELAB_PATH}/linux \
    && mkdir -p ${DEEPFACELAB_WORKSPACE} \
    && cp -rvf ${DEEPFACELAB_PATH}/linux/scripts ${DEEPFACELAB_SCRIPTS} \
    && rm -rvf ${ANACONDA_PATH}/share/jupyter/lab/staging ${DEEPFACELAB_PATH}/linux

# Switch back to root
USER root

COPY ./env.sh ${DEEPFACELAB_SCRIPTS}/env.sh

RUN fix-permissions ${DEEPFACELAB_WORKSPACE} \
    && chmod +x ${DEEPFACELAB_SCRIPTS}/*.sh \
    && fix-permissions ${DEEPFACELAB_SCRIPTS} \
    && ln -s ${DEEPFACELAB_PATH} ${HOME}/deepfacelab \
    && ln -s ${DEEPFACELAB_WORKSPACE} ${HOME}/workspace \
    && ln -s ${DEEPFACELAB_SCRIPTS} ${HOME}/scripts

# Clean Anaconda
RUN conda clean -afy

# Clean packages and caches
RUN apt-get --purge -y autoremove git \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && rm -rvf /home/${ANACONDA_PATH}/.cache/yarn \
    && fix-permissions ${HOME} \
    && fix-permissions ${ANACONDA_PATH}

# Re-activate user "anaconda"
USER $ANACONDA_UID
WORKDIR $HOME
