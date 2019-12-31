When using a GLVND-only Nvidia driver (435+) with Primus, PRIMUS_libGLa needs to point to libGLX_nvidia.so.0 to work. Add an option to override the default hard-coded libGL.so.1, set its default to the old value and document its purpose in the configuration file.

Suggested-by: Felix Dörre debian@felixdoerre.de

=> Change in the script /usr/bin/primusrun or when compiling /usr/lib64/primus/libGL.so
or do the link libGL.so.1 -> libGLX_nvidia.so.440.44 inside /usr/lib64/nvidia-bumblebee

Twice are done in this fork.

Tested with my Dell M4800 laptop with dual graphic card NVIDIA.
GLX works correctly.
Tested with :
> primusrun glxgears
