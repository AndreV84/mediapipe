It is an effort to incorporate medipipe to Jetson ecosystem; tested on Jetson Xavier AGX. aarch64,Linux Tegra
### Contents
- [References](#references)
- [Installing bazel](#installing-bazel--dependencies)
- [Downloading sample video](#downloading-video-sample)
- [Downloading mediapipe sources and patching](#downloading-mediapipe--patching)
- [Adjusting mediapipe opencv config paths](#editing-mediapipe-config-files-to-match-opencv-installation)
- [Building example and running](#building-and-running-an-example)
- [Setting up loopback](#using-cpu-expensive-v4l2loopback-for-webcamera-mode-of-nvargus-csi-jetson-sensor)
- [Using webcam mode of Jetson CSI sensor via loopback](#running-hand-webcam-sample-using-v4l2loop-above)
- [Direct access to CSI sensor without the loopback](#under-construction-running-webcam-hand-sample-with-direct-nvargus-access)
- [Docker implementation](#Docker-hand-usb-cam-GPU-example)

        
## Reference:

Reference threads:

https://github.com/google/mediapipe/issues/655

https://forums.developer.nvidia.com/t/mediapipe/121120/8

https://github.com/mgyong/awesome-mediapipe/blob/master/README.md#nvidia-jetson-integration-draft-beta

Mediapipe docs:

https://mediapipe.readthedocs.io/en/latest/multi_hand_tracking_desktop.html?highlight=multi#tensorflow-lite-multi-hand-tracking-demo-with-webcam-gpu

# Installing Bazel & Dependencies
```
sudo nvpmodel -m0 && sudo jetson_clocks --fan # enabling max performance mode
cd ~ && mkdir bazel && cd bazel && wget https://github.com/bazelbuild/bazel/releases/download/4.0.0/bazel-4.0.0-dist.zip
sudo apt-get install build-essential openjdk-8-jdk python zip unzip
unzip bazel-4.0.0-dist.zip
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh
sudo cp ~/bazel/output/bazel /usr/local/bin/
```

# Downloading video sample 
```
cd ~/Downloads && wget https://raw.githubusercontent.com/chintan9/react-plyr-example/master/Big_Buck_Bunny_1080_10s_30MB.mp4
```
# Downloading mediapipe & patching

```
cd ~ && git clone https://github.com/google/mediapipe/
cd mediapipe
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11  mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu
# it will fail but will provide path that will need to be patched; In my case it is
#/home/nvidia/.cache/bazel/_bazel_nvidia/ff4425722229fc486cc849b5677abe3f/external/com_github_glog_glog/
```
```
# cd to the /external/com_github_glog_glog/ folder detected by the output message of execution above
# delete or remove two files from there:
```
```
##~/.cache/bazel/_bazel_nvidia/ff4425722229fc486cc849b5677abe3f/external/com_github_glog_glog$ mv config.sub config.sub.bak && mv config.guess config.guess.bak
```

```
# Install updated files instead:

wget https://raw.githubusercontent.com/AndreV84/mediapipe/master/config.guess

wget https://raw.githubusercontent.com/AndreV84/mediapipe/master/config.sub
```

# Editing mediapipe config files to match opencv installation:
```
#opencv wil require gtk2/3 libraries to be pre requisites
#sudo apt install libgtk2.0-dev
#sudo apt-get install -y libgtk-3-dev
# editing file WORKSPACES in the mediapipe folder:

# In my case I am installing opencv4.5-1 in a custom manner using drafted commands from here # 

https://github.com/AndreV84/mediapipe/blob/master/opencv4-5-0-cmake

# cmake -D WITH_CUDA=ON -D CUDA_ARCH_BIN="7.2" -D CUDA_ARCH_PTX="" -D WITH_CUDNN=ON -D OPENCV_DNN_CUDA=ON -DWITH_CUBLAS=1 -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.5.3/modules -D WITH_OPENCLAMDFFT=OFF -D WITH_OPENCLAMDBLAS=OFF -DWITH_VA_INTEL=OFF -DWITH_OPENCL=OFF  -D WITH_GSTREAMER=ON -D WITH_LIBV4L=ON -D BUILD_opencv_python2=ON -D BUILD_opencv_python3=ON -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_EXAMPLES=OFF -D OPENCV_GENERATE_PKGCONFIG=ON -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local/opencv-4.5.3-dev -D CUDNN_VERSION="8.0" -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 ../../opencv-4.5.3

#
#
# I assume that from opencv_contrib modules only optflow/cudev/imageproc are required
```
```
new_local_repository(

name = "linux_opencv",

build_file = "@//third_party:opencv_linux.BUILD",

path = "/usr/local/opencv-4.5.1-dev/",
```
```
```
```
# editing opencv_linux.BUILD file in the third_party folder in the mediapipe folder:
```
```
cc_library(
name = "opencv",
srcs = glob(
[
"lib/libopencv_core.so",
"lib/libopencv_calib3d.so",
"lib/libopencv_features2d.so",
"lib/libopencv_highgui.so",
"lib/libopencv_imgcodecs.so",
"lib/libopencv_imgproc.so",
"lib/libopencv_video.so",
"lib/libopencv_videoio.so",
],
),
hdrs = glob(["include/opencv4/**/.h"]),
includes = ["include/opencv4"],
linkstatic = 1,
visibility = ["//visibility:public"],
)
```
# building and Running an example
```
#export export OPENCV_VERSION=opencv-4.5.1-dev
#export LD_LIBRARY_PATH=/usr/local/$OPENCV_VERSION/lib
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu

GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt 
 --input_video_path=/home/nvidia/Downloads/Big_Buck_Bunny_1080_10s_30MB.mp4 --output_video_path=/home/nvidia/Downloads/output.mp4
```



# running hand webcam 


```
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11     mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu
    
    GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt 


```
#  running webcam hand sample with direct nvargus access
#USING PATCHED FILE https://github.com/AndreV84/mediapipe/blob/master/demo_run_graph_main_gpu_mod.cc 
#the file got obsolete but could be used as modification template
#it contains modified fragment that uses rather CSI than USB camera
#for opencv >=4.5.1 use the file [also renameit removing the tail _updated in the filename] # # #  #https://github.com/AndreV84/mediapipe/blob/master/demo_run_graph_main_gpu_mod.cc_updated

#  building face GPU mesh example
```
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 mediapipe/examples/desktop/face_mesh:face_mesh_gpu
```
 # runing the gpu face mesh example
 ```
 export OPENCV_VERSION=opencv-4.5.1-dev
  export LD_LIBRARY_PATH=/usr/local/$OPENCV_VERSION/lib

GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/face_mesh/face_mesh_gpu --calculator_graph_config_file=mediapipe/graphs/face_mesh/face_mesh_desktop_live_gpu.pbtxt
```
   # Iris GPU
    bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11  mediapipe/examples/desktop/iris_tracking:iris_tracking_gpu
    GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/iris_tracking:iris_tracking_gpu--calculator_graph_config_file=mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt
    //known issues https://github.com/google/mediapipe/issues/1265#issuecomment-723389064
    // we have to comment in the file mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt
    // the following line : #  input_side_packet: "FOCAL_LENGTH:focal_length_pixel"


# Upper Pose
```
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11  mediapipe/examples/desktop/upper_body_pose_tracking/upper_body_pose_tracking_gpu
    GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/upper_body_pose_tracking/upper_body_pose_tracking_gpu--calculator_graph_config_file=mediapipe/graphs/pose_tracking/upper_body_pose_tracking_gpu.pbtxt
 ```   

# Docker-hand-usb-cam-GPU-example
single command execution [ simplified ]
```
export DISPLAY=:0 #or 1 in accordance with your environment
xhost +
docker run -it --rm --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/argus_socket:/tmp/argus_socket --cap-add SYS_PTRACE --device /dev/video0:/dev/video0 iad.ocir.io/idso6d7wodhe/mediapipe:latest /bin/bash -c 'GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt'
```
# Docker-hand-usb-video0-example-building-container-locally
```
git clone https://github.com/google/mediapipe.git
cd mediapipe
mv Dockerfile bak_Dockerfile
wget https://raw.githubusercontent.com/AndreV84/mediapipe/master/Dockerfile
docker build --tag=mediapipe .
export DISPLAY=:0 #or 1
xhost +
docker run -it --rm --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/argus_socket:/tmp/argus_socket --cap-add SYS_PTRACE --device /dev/video0:/dev/video0 --name mediapipe mediapipe:latest /bin/bash -c 'GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt'
 ```
 
 # Docker iris
 ```
  export DISPLAY=:0
  xhost +
 docker run -it --rm --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/argus_socket:/tmp/argus_socket --cap-add SYS_PTRACE --device /dev/video0:/dev/video0  iad.ocir.io/idso6d7wodhe/mediapipe:latest /bin/bash -c 'GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/iris_tracking/iris_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt'
 ```
 # Docker pose tracking
 ```
  export DISPLAY=:0
  xhost +
docker run -it --rm --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/argus_socket:/tmp/argus_socket --cap-add SYS_PTRACE --device /dev/video0:/dev/video0  iad.ocir.io/idso6d7wodhe/mediapipe:latest /bin/bash -c 'GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/pose_tracking/pose_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/pose_tracking/pose_tracking_gpu.pbtxt'
 ```
  # Docker face mesh
  ```
  export DISPLAY=:0
  xhost +
 docker run -it --rm --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/argus_socket:/tmp/argus_socket --cap-add SYS_PTRACE --device /dev/video0:/dev/video0 iad.ocir.io/idso6d7wodhe/mediapipe:latest /bin/bash -c 'GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/face_mesh/face_mesh_gpu --calculator_graph_config_file=mediapipe/graphs/face_mesh/face_mesh_desktop_live_gpu.pbtxt'
  ```



