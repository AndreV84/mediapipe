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

        
## Reference:

Reference threads:

https://github.com/google/mediapipe/issues/655

https://forums.developer.nvidia.com/t/mediapipe/121120/8

https://github.com/mgyong/awesome-mediapipe/blob/master/README.md#nvidia-jetson-integration-draft-beta

Mediapipe docs:

https://mediapipe.readthedocs.io/en/latest/multi_hand_tracking_desktop.html?highlight=multi#tensorflow-lite-multi-hand-tracking-demo-with-webcam-gpu

# Installing Bazel & Dependencies
```
sudo nvpmoodel -m0 && sudo jetson_clocks # enabling max performance mode
cd ~ && mkdir bazel && cd bazel && wget https://github.com/bazelbuild/bazel/releases/download/3.4.0/bazel-3.4.0-dist.zip
sudo apt-get install build-essential openjdk-8-jdk python zip unzip
unzip bazel-3.4.0-dist.zip
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
# editing file WORKSPACES in the mediapipe folder:

# In my case I am installing opencv4.5-0 in a custom manner using drafted commands from here # 

https://github.com/AndreV84/mediapipe/blob/master/opencv4-5-0-cmake

# I assume that from opencv_contrib modules only optflow/cudev/imageproc are required
```
```
new_local_repository(

name = "linux_opencv",

build_file = "@//third_party:opencv_linux.BUILD",

path = "/usr/local/opencv-4.5.0-dev/",
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
#export OPENCV_DIR=opencv-4.5.0-dev
#export LD_LIBRARY_PATH=/usr/local/$OPENCV_VERSION/lib
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu

GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_mobile.pbtxt --input_video_path=/home/nvidia/Downloads/Big_Buck_Bunny_1080_10s_30MB.mp4 --output_video_path=/home/nvidia/Downloads/output.mp4
```



# running hand webcam 


```
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11     mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu
    
    GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_mobile.pbtxt

```
#  running webcam hand sample with direct nvargus access
USING PATCHED FILE https://github.com/AndreV84/mediapipe/blob/master/demo_run_graph_main_gpu_mod.cc 
it contains modified fragment that uses rather CSI than USB camera
