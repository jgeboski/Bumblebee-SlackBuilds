When using a GLVND-only Nvidia driver (435+) with Primus, PRIMUS_libGLa needs to point to libGLX_nvidia.so.0 to work. Add an option to override the default hard-coded libGL.so.1, set its default to the old value and document its purpose in the configuration file.

Suggested-by: Felix Dörre debian@felixdoerre.de

=> Changer dans le script /usr/bin/primusrun ou a la compilation de /usr/lib64/primus/libGL.so
ou Faire le lien libGL.so.1 -> libGLX_nvidia.so.440.44 dans /usr/lib64/nvidia-bumblebee

Les 2 sont appliques dans Crazybee
