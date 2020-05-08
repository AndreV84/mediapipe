### Contents
- [References](#references)
- [Installing bazel](#installing-bazel--dependencies)
- [Downloading sample video](#downloading-video-sample)
- [Downloading mediapipe sources and patching](#downloading-mediapipe--patching)
- [Adjusting mediapipe opencv config paths](#editing-mediapipe-config-files-to-match-opencv-installation)
- [Building example and running](#building-and-running-an-example)
- [Setting up loopback](#using-cpu-expencive-v4l2loopback-for-webcamera-mode-of-nvargus-csi-jetson-sensor)
- [Using webcam mode of Jetson CSI sensor via loopback](#running-hand-webcam-sample-using-v4l2loop-above)
- [Direct access to CSI sensor without the loopback](#under-construction-running-webcam-hand-sample-with-direct-nvargus-access)

        
## Seference:
It is an effort to incorporate medipipe to Jetson ecosystem; tested on Jetson Xavier AGX. aarch64,Linux Tegra
Reference threads:

https://github.com/google/mediapipe/issues/655

https://forums.developer.nvidia.com/t/mediapipe/121120/8

https://github.com/mgyong/awesome-mediapipe/blob/master/README.md#nvidia-jetson-integration-draft-beta

Mediapipe docs:

https://mediapipe.readthedocs.io/en/latest/multi_hand_tracking_desktop.html?highlight=multi#tensorflow-lite-multi-hand-tracking-demo-with-webcam-gpu

# Installing Bazel & Dependencies
```
sudo nvpmoodel -m0 && sudo jetson_clocks # enabling max performance mode
cd ~ && mkdir bazel && cd bazel && wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-dist.zip
sudo apt-get install build-essential openjdk-8-jdk python zip unzip
unzip bazel-3.1.0-dist.zip
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
# getting updated files, downloaded from  https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD
# https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD 
```
wget https://raw.githubusercontent.com/AndreV84/mediapipe/master/config.guess

wget https://raw.githubusercontent.com/AndreV84/mediapipe/master/config.sub
```
```
# Editing mediapipe config files to match opencv installation:
```
# editing file WORKSPACES in the mediapipe folder:

# In my case I am installing opencv4.3 in a custom manner using drafted commands from here # 

https://github.com/AndreV84/Jetson/blob/master/opencv43

# I assume that from opencv_contrib modules only optflow is required
```
```
new_local_repository(

name = "linux_opencv",

build_file = "@//third_party:opencv_linux.BUILD",

path = "/usr/local/opencv-4.3.0-dev/",
```
```
```
```
# editing opencv BUILD file in the third_party folder in the mediapipe folder:
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
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu

GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_mobile.pbtxt --input_video_path=/home/nvidia/Downloads/Big_Buck_Bunny_1080_10s_30MB.mp4 --output_video_path=/home/nvidia/Downloads/output.mp4
```
# using cpu expencive v4l2loopback for webcamera mode of nvargus CSI Jetson sensor:
```
sudo su
cd /usr/src/linux-headers-4.9.140-tegra-ubuntu18.04_aarch64/kernel-4.9
## dropped in latter release##make modules_prepare
mkdir v4l2loopback
git clone https://github.com/umlaeute/v4l2loopback.git v4l2loopback
cd v4l2loopback && git checkout -b v0.10.0
make
## if the sequence above fails - adopt the line: make -C /lib/modules/4.9.140-tegra/build M=`$pwd` modules
## make -C /lib/modules/`uname -r`-tegra/build M=/usr/src/v4l2loopback modules_install

make install
apt-get install -y v4l2loopback-dkms v4l2loopback-utils
modprobe v4l2loopback devices=1 video_nr=2 exclusive_caps=1
echo options v4l2loopback devices=1 video_nr=2 exclusive_caps=1 > /etc/modprobe.d/v4l2loopback.conf
echo v4l2loopback > /etc/modules
update-initramfs -u
```
# running v4l2loopback from separate terminal
```
gst-launch-1.0 -v nvarguscamerasrc ! 'video/x-raw(memory:NVMM), format=NV12, width=1920, height=1080, framerate=30/1' ! nvvidconv ! 'video/x-raw, width=640, height=480, format=I420, framerate=30/1' ! videoconvert ! identity drop-allocation=1 ! 'video/x-raw, width=640, height=480, format=RGB, framerate=30/1' ! v4l2sink device=/dev/video2
```

# running hand webcam sample using v4l2loop above:

/// as the lopback will render sensor 02 the value 0 will need to be changed to 02 at the file
/// https://github.com/google/mediapipe/blob/master/mediapipe/examples/desktop/demo_run_graph_main_gpu.cc#L73
/mediapipe/blob/master/mediapipe/examples/desktop/demo_run_graph_main_gpu.cc , line 73
changing 0 to 2. capture.open(0); -> capture.open(2);
```
bazel build -c opt --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11     mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu
    
    GLOG_logtostderr=1 bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu --calculator_graph_config_file=mediapipe/graphs/hand_tracking/hand_tracking_mobile.pbtxt

```
# under construction: running webcam hand sample with direct nvargus access
editing the file  demo_run_graph_main_gpu.cc
modified fragment
```
`LOG(INFO) << "Initialize the camera or load the video.";
  cv::VideoCapture capture;
  const bool load_video = !FLAGS_input_video_path.empty();
  const char* gst =  "nvarguscamerasrc ! video/x-raw(memory:NVMM), width=1280, height=720 !  nvvidconv ! video/x-raw,format=I420 ! appsink";
  
if (load_video) {
    capture.open(FLAGS_input_video_path);
  } else {
    capture.open(gst, cv::CAP_GSTREAMER);
  }
  RET_CHECK(capture.isOpened());

  cv::VideoWriter writer;
  const bool save_video = !FLAGS_output_video_path.empty();
  if (!save_video) {
    cv::namedWindow(kWindowName, /*flags=WINDOW_AUTOSIZE*/ 1);
#if (CV_MAJOR_VERSION >= 3) && (CV_MINOR_VERSION >= 2)
    capture.set(cv::CAP_PROP_FRAME_WIDTH, 1280);
    capture.set(cv::CAP_PROP_FRAME_HEIGHT, 720);
    capture.set(cv::CAP_PROP_FPS, 120);
#endif`
```
so it will read directly freom nvargus, but the latter wil throw an error; it needs to be investigated further

