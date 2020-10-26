#!/bin/bash
#
#
# Script to compile opencv without gpu support.
#
#
OPENCV_VER=4.5.0
OPENCV_URL=https://github.com/opencv/opencv/archive/$OPENCV_VER.zip
OPENCV_CONTRIB_URL=https://github.com/opencv/opencv_contrib/archive/$OPENCV_VER.zip
#
# Compile opencv
#

logger "Compiling opencv without GPU Support" -tEventServer

cd ~
wget -q -O opencv.zip $OPENCV_URL
wget -q -O opencv_contrib.zip $OPENCV_CONTRIB_URL
unzip opencv.zip
unzip opencv_contrib.zip
mv $(ls -d opencv-*) opencv
mv opencv_contrib-$OPENCV_VER opencv_contrib
rm *.zip

logger "Compiling opencv..." -tEventServer

cd ~/opencv
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
	-D HAVE_opencv_python3=ON \
	-D PYTHON_EXECUTABLE=/usr/bin/python3 \
	-D PYTHON2_EXECUTABLE=/usr/bin/python2 \
	-D BUILD_EXAMPLES=OFF .. >/dev/null

make -j$(nproc)

logger "Installing opencv..." -tEventServer
make install

logger "Cleaning up..." -tEventServer
cd ~
rm -r opencv*
