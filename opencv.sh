#!/bin/bash
#

#
# Script to compile opencv with CUDA support.
# https://www.pyimagesearch.com/2020/02/03/how-to-use-opencvs-dnn-module-with-nvidia-gpus-cuda-and-cudnn/
#

#
# Set the number of cpu cores in your docker.
#
NO_OF_CORES=8

# uninstall opencv package
pip3 uninstall opencv-contrib-python

# compile opencv with cuda support
apt-get -y install build-essential cmake unzip pkg-config
apt-get -y install libjpeg-dev libpng-dev libtiff-dev
apt-get -y install libavcodec-dev libavformat-dev libswscale-dev
apt-get -y install libv4l-dev libxvidcore-dev libx264-dev
apt-get -y install libgtk-3-dev
apt-get -y install libatlas-base-dev gfortran
apt-get -y install python3-dev

cd ~
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.2.0.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.2.0.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.2.0 opencv
mv opencv_contrib-4.2.0 opencv_contrib

cd ~/opencv
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=ON \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D WITH_CUDA=ON \
	-D WITH_CUDNN=ON \
	-D OPENCV_DNN_CUDA=ON \
	-D ENABLE_FAST_MATH=1 \
	-D CUDA_FAST_MATH=1 \
	-D WITH_CUBLAS=1 \
	-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
	-D HAVE_opencv_python3=ON \
	-D PYTHON_EXECUTABLE=~/.virtualenvs/opencv_cuda/bin/python \
	-D BUILD_EXAMPLES=ON ..

make -j$NO_OF_CORES
make install
ldconfig

cd ~
rm -r opencv*
