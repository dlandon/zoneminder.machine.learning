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
# Other Systems: Remove the docker image then reinstall it.
# Hook processing has to be enabled to run this script.
#
# Install the Unraid Nvidia plugin or the Nvidia docker on other systems and be sure your graphics card can be seen in the
# Zoneminder Docker.
# You will not get a proper compile if your graphics card is not seen.
#
# Download the cuDNN run time and dev packages for your GPU configuration.  You want the deb packages for Ubuntu 18.04.
# You wll need to have an account with Nvidia to download these packages.
# https://developer.nvidia.com/rdp/form/cudnn-download-survey
# Place them in the /config folder.
#
CUDNN_RUN=libcudnn7_7.6.5.32-1+cuda10.2_amd64.deb
CUDNN_DEV=libcudnn7-dev_7.6.5.32-1+cuda10.2_amd64.deb
#
# Download the cuda package for your GPU configuration.  You want the deb package for Ubuntu 18.04.
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1804&target_type=deblocal
# Place the download in the /config folder.
#
# Unraid has moved to driver version 440 and cuda 10.2
#
CUDA_TOOL=cuda-repo-ubuntu1804-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb
CUDA_PIN=cuda-ubuntu1804.pin
CUDA_KEY=/var/cuda-repo-10-2-local-10.2.89-440.33.01/7fa2af80.pub
CUDA_VER=10.2
#
#
# Github URL for opencv zip file download.
# Current default is to pull the version 4.2.0 release.
#
OPENCV_URL=https://github.com/opencv/opencv/archive/4.2.0.zip
#
# Uncomment the following URL to pull commit to support cudnn for older nvidia gpus
#
# OPENCV_URL=https://github.com/opencv/opencv/archive/282fcb90dce76a55dc5f31246355fce2761a9eff.zip
#
#############################################################################################################################

#
# Be sure we have enough disk space to compile opencv.
#
SPACE_AVAIL=`/bin/df / | /usr/bin/awk '{print $4}' | grep -v 'Available'`
if [[ $((SPACE_AVAIL/1000)) < 15360 ]];then
	echo
	echo "Not enough disk space to compile opencv!"
	echo "Expand your Docker image to leave 15GB of free space."
	echo "Force update or remove and re-install Zoneminder to allow more space if your compile did not complete."
	exit
fi

#
# Check for enough memory to compile opencv.
#
MEM_AVAILABLE=`cat /proc/meminfo | grep MemAvailable | /usr/bin/awk '{print $2}'`
if [[ $((MEM_AVAILABLE/1000)) < 4096 ]];then
	echo
	echo "Not enough memory available to compile opencv!"
	echo "You should have at least 3GB available."
	echo "Check that you have not over committed SHM."
	exit
fi

#
# Insure hook processing has been installed.
#
if [ "$INSTALL_HOOK" != "1" ]; then
	echo "Hook processing has to be installed before you can compile opencv!"
	exit
fi

logger "Compiling opencv with GPU Support" -tEventServer

#
# Remove hook installed opencv module and face-recognition module
#
pip3 uninstall opencv-contrib-python
if [ "$INSTALL_FACE" == "1" ]; then
	pip3 uninstall face-recognition
fi

#
# Install cuda toolkit
#
logger "Installing cuda toolkit..." -tEventServer
cd ~
if [ -f  /config/$CUDA_PIN ]; then
	cp /config/$CUDA_PIN /etc/apt/preferences.d/cuda-repository-pin-600
else
	echo "Please download CUDA_PIN."
	exit
fi

if [ -f /config/$CUDA_TOOL ];then
	dpkg -i /config/$CUDA_TOOL
else
	echo "Please download CUDA_TOOL package."
	exit
fi

apt-key add $CUDA_KEY
apt-get update
apt-get -y upgrade -o Dpkg::Options::="--force-confold"
apt-get -y install cuda-$CUDA_VER

echo "export PATH=/usr/local/cuda/bin:$PATH" >/etc/profile.d/cuda.sh
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/lib:$LD_LIBRARY_PATH" >> /etc/profile.d/cuda.sh
echo "export CUDADIR=/usr/local/cuda" >> /etc/profile.d/cuda.sh
echo "export CUDA_HOME=/usr/local/cuda" >> /etc/profile.d/cuda.sh
echo "/usr/local/cuda/lib64" > /etc/ld.so.conf.d/cuda.conf
ldconfig

#
# check for expected install location
#
cudadir=/usr/local/cuda-$CUDA_VER
if [ ! -d "$cudadir" ]; then
    logger "Failed to install cuda toolkit"
    exit
elif [ ! -L "/usr/local/cuda" ]; then
    ln -s $cudadir /usr/local/cuda
fi

logger "Cuda toolkit installed" -tEventServer

if [ -x /usr/bin/nvidia-smi ]; then
	echo "##################################################################################"
	echo ""
	/usr/bin/nvidia-smi
	echo "##################################################################################"
	echo "Verify your Nvidia GPU is seen and the driver is loaded."
	echo "If not stop the script and fix the problem."
	echo "Press any key to continue, or ctrl-C to stop."
	read -n 1 -s
else
	echo "Cuda install failed.  'nvidia-smi' not found!"
	exit
fi

#
# Install cuDNN run time and dev packages
#
logger "Installing cuDNN Package..." -tEventServer
#
if [ -f /config/$CUDNN_RUN ];then
	dpkg -i /config/$CUDNN_RUN
else
	echo "Please download CUDNN_RUN package."
	exit
fi
if [ -f /config/$CUDNN_DEV ];then
	dpkg -i /config/$CUDNN_DEV
else
	echo "Please download CUDNN_DEV package."
	exit
fi
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
wget -O opencv.zip $OPENCV_URL
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.2.0.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv $(ls -d opencv-*) opencv
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

echo "######################################################################################"
echo ""

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
	-D BUILD_EXAMPLES=OFF ..

echo "######################################################################################"
echo "Verify that CUDA and cuDNN are both enabled in the cmake output above."
echo "Look for the lines with CUDA and cuDNN."
echo "You may have to scroll up the page to see them."
echo "If those lines don't show 'YES', then stop the script and fix the problem."
echo "Check that you have the correct versions of CUDA ond cuDNN for your GPU."
echo "Press any key to continue, or ctrl-C to stop."
read -n 1 -s

make -j$(nproc)
make install
ldconfig

#
# Now reinstall face-recognition package to ensure it detects GPU.
#
if [ "$INSTALL_FACE" == "1" ]; then
	pip3 install face-recognition
fi

#
# Clean up/remove unnecessary packages
#
logger "Cleaning up..." -tEventServer

cd ~
rm -r opencv*
rm -f /etc/my_init.d/20_apt_update.sh

logger "Opencv compile completed." -tEventServer

echo "Compile is complete."
echo "Now check that the cv2 module in python is working."
echo "Execute the following commands:"
echo "  python3"
echo "  import cv2"
echo
echo "Verify that the import does not show errors."
echo "If it doesn't, then you have successfully compiled opencv."
