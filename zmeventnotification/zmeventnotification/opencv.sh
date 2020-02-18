#!/bin/bash
#
#
# Script to compile opencv with CUDA support.
#
#############################################################################################################################
#
# You need to prepare for compiling the opencv with CUDA support.
#
# You need to start with a clean docker image if you are going to recompile opencv.
# Unraid: This can be done by switching to "Advanced View" and clicking "Force Update".
# Other SYstems: Remove the docker image then reinstall it.
# Hook processing has to be enabled to run this script.
#
# Install the Unraid Nvidia plugin or the Nvidia docker and be sure your graphics card can be seen in the Zoneminder Docker.
# You will not get a proper compile if your graphics card is not seen.
#
# Download the cuDNN run time and dev packages for your GPU configuration.  You want the deb packages for Ubuntu 18.04.
# You wll need to have an account with Nvidia to download these packages.
# https://developer.nvidia.com/rdp/form/cudnn-download-survey
# Place them in the /config folder.
#
CUDNN_RUN=libcudnn7_7.6.5.32-1+cuda10.1_amd64.deb
CUDNN_DEV=libcudnn7-dev_7.6.5.32-1+cuda10.1_amd64.deb
#
# Download the cuda package for your GPU configuration.  You want the deb package for Ubuntu 18.04.
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1804&target_type=deblocal
# Place the download in the /config folder.
#
CUDA_TOOL=cuda-repo-ubuntu1804-10-1-local-10.1.168-418.67_1.0-1_amd64.deb
CUDA_KEY=/var/cuda-repo-10-1-local-10.1.168-418.67/7fa2af80.pub
#
#############################################################################################################################
#
# Insure hook processing has been installed.
#
if [ "$INSTALL_HOOK" != "1" ]; then
	echo "Hook processing has to be installed before you can compile opencv!"
	exit 1
fi

logger "Compiling opencv with GPU Support" -tEventServer

#
# Remove hook installed opencv module
#
pip3 uninstall opencv-contrib-python

#
# Install cuda toolkit
#
logger "Installing cuda toolkit..." -tEventServer
cd ~
dpkg -i /config/$CUDA_TOOL
apt-key add $CUDA_KEY
apt-get update
apt-get -y upgrade -o Dpkg::Options::="--force-confold"
apt-get -y install cuda

echo "export PATH=/usr/local/cuda/bin:$PATH" >/etc/profile.d/cuda.sh
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/lib:$LD_LIBRARY_PATH" >> /etc/profile.d/cuda.sh
echo "export CUDADIR=/usr/local/cuda" >> /etc/profile.d/cuda.sh
echo "export CUDA_HOME=/usr/local/cuda" >> /etc/profile.d/cuda.sh
echo "/usr/local/cuda/lib64" > /etc/ld.so.conf.d/cuda.conf
ldconfig
logger "Cuda toolkit installed" -tEventServer

#
# Install cuDNN run time and dev packages
#
logger "Installing cuDNN Package..." -tEventServer
dpkg -i /config/$CUDNN_RUN
dpkg -i /config/$CUDNN_DEV
logger "cuDNN Package installed" -tEventServer

#
# Compile opencv with cuda support
#
logger "Installing cuda support packages..." -tEventServer
apt-get -y install libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev
apt-get -y install libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran
logger "Cuda support packages installed" -tEventServer

#
# Get opencv source
#
logger "Downloading opencv source..." -tEventServer
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.2.0.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.2.0.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.2.0 opencv
mv opencv_contrib-4.2.0 opencv_contrib
rm *.zip

cd ~/opencv
mkdir build
cd build
logger "Opencv source downloaded" -tEventServer

#
# Make opencv
#
logger "Compiling opencv..." -tEventServer

cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
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
	-D PYTHON_EXECUTABLE=/usr/bin/python3 \
	-D CUDA_ARCH_BIN=7.5 \
	-D BUILD_EXAMPLES=OFF ..

make -j$(nproc)
make install
ldconfig
logger "Opencv compiled" -tEventServer

#
# Clean up/remove unnecessary packages
#
logger "Cleaning up..." -tEventServer
cd ~
rm -r opencv*
apt-get -y remove cuda
apt-get -y remove libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev
apt-get -y remove libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran
apt-get -y autoremove

#
# Add opencv module wrapper
#
pip3 install opencv-contrib-python

logger "Opencv sucessfully compiled" -tEventServer
