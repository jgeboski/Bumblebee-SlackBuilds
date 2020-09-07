# Bumblebee Slackbuilds

This set of SlackBuilds should get Bumblebee up and running on a
Slackware based NVIDIA Optimus setup.

## Slackbuilds HowTo:
  If you have never used a SlackBuild before, please refer to the HowTo
  on SlackBuilds.org: http://slackbuilds.org/howto/

  All the Slackbuild scripts were designed to be run as root, with root's
  environment. ( i.e. su - )

## Notes:
  Several of these SlackBuilds support a COMPAT32 option which
  allows 32-bit binaries to be built and packaged. This does
  require that the system is multilib, otherwise the SlackBuilds
  will fail.

  For more information on slackware multilib, visit AlienBOB's wiki:
  http://alien.slackbook.org/dokuwiki/doku.php?id=slackware:multilib

  As of this time, the nouveau drivers are still pretty poor substitutes
  for the Nvidia binaries. Performance in 3D games will likely be worse
  and less stable than the intel drivers and card provide. However,
  installing the bumblebee and bbswitch will allow the nvidia card to at
  least be disabled when not in use, saving you power, even if you do not
  use the closed source nvidia drivers.

## Building and Installing

### The AUTOMATIC way:
---

Note that this script runs as root, and will exit if you already have the repo downloaded.
 - USE AT YOUR OWN RISK!

If you modify the builds in any way this script IS NOT FOR YOU.

This script will (in addition to downloading & installing everything in order):

 - Detect Multilib
 - Create the necessary /etc/rc.d/rc.local* entries
 - Create the bumblebee group and add all normal users to it
 - Add a copy of crazybee inside of ~/Bumblebee-SlackBuilds/ for reinstalls

Simply run this as root:

Current:

    curl https://raw.githubusercontent.com/ryanpcmcquen/linuxTweaks/master/slackware/crazybee.sh | sh

Stable:

    curl https://raw.githubusercontent.com/ryanpcmcquen/linuxTweaks/master/slackware/crazybee.sh | STABLE=yes sh

P.S. This script uses upgradepkg --reinstall --install-new, so you can use it after kernel upgrades.
;^)

For reinstalls, run:

Current:

    sh ~/Bumblebee-SlackBuilds/crazybee.sh

Stable:

    STABLE=yes sh ~/Bumblebee-SlackBuilds/crazybee.sh


### The MANUAL way:
---

### 1. Download the sources:
```
    ./download.sh
```

### 2. Create group bumblebee:
```
    su -
    groupadd bumblebee
```
  Add users to the group:
```
    usermod -G bumblebee -a USERNAME
```
  Note: you will need to re-login as the user for this to take effect.

### 3. Build and install `libbsd`:
```
    cd libbsd
    ./libbsd.Slackbuild
    upgradepkg --install-new /tmp/libbsd-<ver-arch-build>_bbsb.txz
    cd ..
```

### 4. Build and install `bumblebee`:
```
    cd bumblebee
    ./bumblebee.Slackbuild
    upgradepkg --install-new /tmp/bumblebee-<ver-arch-build>_bbsb.txz
    cd ..
```

### 5. Build and install `bbswitch` (Optional but recommended):
```
    cd bbswitch
    ./bbswitch.Slackbuild
    upgradepkg --install-new /tmp/bbswitch-<ver-arch-build>_bbsb.txz
    cd ..
```
  - Note:
  This in an optional requirement. This is the kernel module that allows
  the Nvidia card to be turned off, potentially saving you power. If you
  do not need power management or the ability to turn off the nVidia chip,
  you can skip this.
  - Note: This will need to be rebuilt when you upgrade the kernel.

### 6. Build and install `primus`:
```
    cd primus
```
  For pure 32 or 64 bit systems, build via:
```
    ./primus.Slackbuild
```
  If the system is x86_64 based, 32-bit compatible binaries and
  libraries can be built via:
```
    COMPAT32=yes ./primus.SlackBuild
```
  Then install:
```
    upgradepkg --install-new /tmp/primus-<ver-arch-build>_bbsb.txz
    cd ..
```
  - Note: due to the sync between framerate and refresh rate, you may not see any difference between primusrun and the intel card in glxgears, although you will see drastic differences playing high end games.  In the past the vblank_mode set to 0 improved framerates and helped with screen tearing, now tho this should only be used for benchmarks or tests:  
```
    vblank_mode=0 primusrun
```

### 7. Blacklist nouveau (or skip steps 8, 9, 10):
```
    cd nouveau-blacklist
    upgradepkg xf86-video-nouveau-blacklist-noarch-1.txz
    cd ..
```
  - Note:
  This will blacklist / remove the conflicting nouveau driver from
  slackware, it will however come back unless you add `xf86-video-nouveau`
  to `/etc/slackpkg/blacklist`

### 8. Build and install `nvidia-kernel` (Optional, not needed if using nouveau):
```
    cd nvidia-kernel
    ./nvidia-kernel.Slackbuild
    upgradepkg --install-new /tmp/nvidia-kernel-<ver-arch-build>_bbsb.txz
    cd ..
```
  - Note: This will need to be rebuilt when you upgrade the kernel.

### 9. Build and install `nvidia-bumblebee` (Optional, not needed if using nouveau):
```
    cd nvidia-bumblebee
```
  For pure 32 or 64 bit systems, build via:
```
    ./nvidia-bumblebee.Slackbuild
```
  If the system is x86_64 based, 32-bit compatible binaries and libraries can
  be built via:
```
    COMPAT32=yes ./nvidia-bumblebee.SlackBuild
```
  Then install:
```
    upgradepkg --install-new /tmp/nvidia-bumblebee-<ver-arch-build>_bbsb.txz
    cd ..
```

### 10. Run the `rc.bumblebee` script:
```
    chmod +x /etc/rc.d/rc.bumblebeed
    /etc/rc.d/rc.bumblebeed start
```
    If you'd like to have bumblebee autostart with the system, you will
    need to add the following lines to `/etc/rc.d/rc.local`:
```
    if [ -x /etc/rc.d/rc.bumblebeed ]; then
        /etc/rc.d/rc.bumblebeed start
    fi
```
    You can also go a step further by having bumblebeed stop with your
    system by adding the following lines to `/etc/rc.d/rc.local_shutdown`:
```
    if [ -x /etc/rc.d/rc.bumblebeed ]; then
        /etc/rc.d/rc.bumblebeed stop
    fi
```

### 11. Reboot:
    Not really a step, but you need to get all the new goodness started somehow.

### 12. Now an application can run with `primusrun`:
```
    primusrun glxgears
```


## CUDA:

This package is completely compatible with the Nvidia CUDA drivers (provided
you use the nvidia proprietary drivers).

Note that this is not part of the automatic installation script!

### 1. Load the NVIDIA Unified Memory kernel module `nvidia_uvm`

This module is required by CUDA to run. If you'd like to have `nvidia_uvm`
be automatically loaded with your system, you will need to add the
following line to `/etc/rc.d/rc.local`:
```
    /usr/bin/nvidia-modprobe -c 0 -u
```
- Note that the `nvidia-modprobe` script executed with this arguments will load
the module and create device communication files `/dev/nvidia-uvm` and
`/dev/nvidia-uvm-tools`. These files will not be automatically created
if you load the module manually via the `modprobe` command.

### 2. Install CUDA Toolkit
Install the `cudatoolkit` package available on SlackBuilds.org:
https://slackbuilds.org/repository/14.2/development/cudatoolkit/. Make sure to
select the correct Slackware version.

- Note that the version of the nvidia driver must be the same as the
`cudatoolkit` version or newer

- Note that the `cudatoolkit` package has another dependency `nvidia-driver`
also available on SlackBuilds.org. You MUST NOT install this dependency as it
conflicts with nvidia-bumblebee and will cause problems in your X-server.

### 3. Configure environment variables
```
    PATH=$PATH:/usr/share/cuda/bin
```
- Note that the above should be executed from a user shell, not root.
If you want, to make it permanent, paste the above in `~/.bashrc`

You also need to allow cuda to find the nvidia libraries. Either add
`/usr/lib64/nvidia-bumblebee` to your `/etc/ld.so.conf` or add it to
your `$LD_LIBRARY_PATH`. For 32-bit compatible systems also add
`/usr/lib/nvidia-bumblebee`. Then update the linker
```
    ldconfig -v
```

### 4. Verify installation
```
    cd /usr/doc/cudatoolkit-*/NVIDIA_CUDA-8.0_Samples/1_Utilities/deviceQuery
    make
    cd ../../bin/x86*/linux/release
    ./deviceQuery
```
If the the very end of the output is `Result = PASS`, then the installation
was successful. Note that the Nvidia GPU has to be ON and all the kernel
modules need to be properly loaded when you run a CUDA program.


## Nvidia Proprietary Driver:
`nvidia-bumblebee` is the package that installs the nvidia proprietary
driver. However, only libraries and tools needed for the core purposes above
are installed. This might be a source of issues if you are looking to enable
additional functionalities. Here is a list of the libraries from the binary
driver that currently are not included in `nvidia-bumblebee`:
```
    libEGL.so.1
    libEGL.so.$VERSION
    libEGL_nvidia.so.$VERSION **Added**
    libGL.so.1.7.0 **Added** **Removed for libglvnd**
    libGL.so.$VERSION **Added**
    libGLESv1_CM.so.1
    libGLESv1_CM_nvidia.so.$VERSION
    libGLESv2.so.2
    libGLESv2_nvidia.so.$VERSION
    libGLESv1_CM.so.1
    libGLESv1_CM_nvidia.so.$VERSION
    libGLESv2.so.2
    libGLESv2_nvidia.so.$VERSION
    libGLX.so.0 **Added** **Removed for libglvnd**
    libGLX_nvidia.so.$VERSION *Added**
    libGLdispatch.so.0 **Added** **Removed for libglvnd**
    libOpenGL.so.0 **Added** **Removed for libglvnd**
    libnvidia-eglcore.so.$VERSION
    libnvidia-ifr.so.$VERSION
    libnvidia-encode.so.$VERSION
    libnvidia-egl-wayland.so.$VERSION
    libnvidia-fbc.so.$VERSION
```
And a list of the tools:
```
    nvidia-persistenced
    nvidia-debugdump
```
For details on the exact functionality of theese libraries and tools, consult
the `README.txt` that becomes available after extracting the driver.

## Known issues

#### Resolved

Running `optirun glxgears` or `primusrun glxgears` gives a blank screen and the
following output.

```
primus: warning: dropping a frame to avoid deadlock
XIO: fatal IO error 11 (Resource temporarily unavailable) on X server ":0"
    after 35 requests (35 known processed) with 0 events remaining.
primus: warning: dropping a frame to avoid deadlock
primus: warning: timeout waiting for display worker
```

This can be circumvented by `__GLVND_DISALLOW_PATCHING=1 optirun glxgears` or
`__GLVND_DISALLOW_PATCHING=1 primusrun glxgears`.
