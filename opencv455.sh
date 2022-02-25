wget https://github.com/opencv/opencv_contrib/archive/refs/tags/4.5.5.zip
unzip 4.5.5.zip 
rm 4.5.5.zip
wget https://github.com/opencv/opencv/archive/4.5.5.zip
unzip 4.5.5.zip
rm 4.5.5.zip
cd opencv-4.5.5
mkdir build
cmake -D WITH_CUDA=ON -D CUDA_ARCH_BIN="7.2" -D CUDA_ARCH_PTX="" -D WITH_CUDNN=ON -D OPENCV_DNN_CUDA=ON -DWITH_CUBLAS=1 -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.5.5/modules -D WITH_GSTREAMER=ON -D WITH_LIBV4L=ON -D BUILD_opencv_python2=ON -D BUILD_opencv_python3=ON -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_EXAMPLES=OFF -D OPENCV_GENERATE_PKGCONFIG=ON -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local/opencv-4.5.5-dev -D CUDNN_VERSION="8.0" -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 ../../opencv-4.5.5
cd build

# export OPENCV_VERSION=opencv-4.5.5-dev
#export LD_LIBRARY_PATH=/usr/local/$OPENCV_VERSION/lib
