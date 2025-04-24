FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Systemtools & Python 3.8
RUN apt update && apt install -y \
    locales \
    lsb-release \
    sudo \
    gnupg \
    curl \
    wget \
    git \
    python3.8-pip \
    python3.8-dev \
    python3.8-venv \
    python-is-python3 \
    build-essential \
    software-properties-common \
    libgl1-mesa-glx \
    libxext6 \
    libxrender-dev \
    libssl-dev \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Locale setzen
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# ROS 2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add - && \
    echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list && \
    apt update && apt install -y ros-humble-desktop python3-colcon-common-extensions && \
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

SHELL ["/bin/bash", "-c"]
RUN source /opt/ros/humble/setup.bash

# CUDA 11.8
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin && \
    mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2204-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt update && apt install -y cuda && \
    rm cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb

ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH


# PyTorch + torchvision (cu118) mit Python 3.8
RUN python3.8 -m pip install --upgrade pip setuptools wheel && \
    python3.8 -m pip install torch==1.13.1+cu118 torchvision==0.14.1+cu118 \
        -f https://download.pytorch.org/whl/torch_stable.html

# mmcv + mmdeploy
RUN python3.8 -m pip install mmcv-full==1.5.3 \
    -f https://download.openmmlab.com/mmcv/dist/cu118/torch1.13.1/index.html && \
    python3.8 -m pip install onnxruntime-gpu==1.14.1

# andere Python Pakete
RUN python3.8 -m pip install \
    mmdet==2.25.1 \
    mmsegmentation==0.25.0 \
    mmdet3d==1.0.0rc4 \
    pycuda \
    lyft_dataset_sdk \
    networkx==2.2 \
    numba==0.57.1 \
    numpy==1.23.5 \
    nuscenes-devkit \
    plyfile \
    scikit-image \
    tensorboard \
    trimesh==2.35.39 \
    matplotlib \
    scipy \
    Pillow \
    imageio \
    openmim \
    spconv \
    setuptools==59.5.0

# mmdeploy installieren
ENV ONNXRUNTIME_DIR=/root/workspace/onnxruntime-linux-x64-1.14.1
ENV TENSORRT_DIR=/root/tensorrt/TensorRT-8.6.1.6
RUN git clone https://github.com/open-mmlab/mmdeploy.git && \
    cd mmdeploy && \
    git checkout tags/v1.0.0 -b v1.0.0 && \
    git submodule update --init --recursive && \
    mkdir -p build && cd build && \
    cmake -DMMDEPLOY_TARGET_BACKENDS="ort;trt" .. && \
    make -j$(nproc) && cd .. && \
    python3.8 -m pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple

# pplcv installieren
RUN git clone https://github.com/openppl-public/ppl.cv.git && \
    cd ppl.cv && \
    git checkout tags/v0.7.0 -b v0.7.0 && \
    ./build.sh cuda

# Arbeitsverzeichnis
WORKDIR /root/workspace

ENV ROS_DISTRO=humble
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc
