Bumblebee Slackbuilds
=====================

This set of SlackBuilds should get Bumblebee up and running on a
Slackware based NVIDIA Optimus setup.

Slackbuilds HowTo:
------------------
  If you have never used a SlackBuild before, please refer to the HowTo
  on SlackBuilds.org: http://slackbuilds.org/howto/

  All the Slackbuild scripts were designed to be run as root, with root's
  environment. ( i.e. su - )

Notes:
------
  Several of these SlackBuilds support a COMPAT32 option which
  allows 32-bit binaries to be built and packaged.  This does
  require that the system is multilib, otherwise the SlackBuilds 
  will fail.

  For more information on slackware multilib, visit AlienBOB's wiki:
  http://alien.slackbook.org/dokuwiki/doku.php?id=slackware:multilib

  As of this time, the nouveau drivers are still pretty poor substitutes
  for the Nvidia binaries. Performance in 3D games will likely be worse
  and less stable than the intel drivers and card provide.  However,
  installing the bumblebee and bbswitch will allow the nvidia card to at
  least be disabled when not in use, saving you power, even if you do not
  use the closed source nvidia drivers.

Building and Installing
-----------------------

1. Download the sources:  
```
    ./download.sh  
```

2. Create group bumblebee:  
```
    su -
    groupadd bumblebee
```
  Add users to the group:  
```
    usermod -G bumblebee -a USERNAME
```
  Note: you will need to re-login as the user for this to take effect.

3. Build and install `libbsd`:  
```
    cd libbsd  
    ./libbsd.Slackbuild  
    upgradepkg --install-new /tmp/libbsd-<ver-arch-build>_bbsb.txz  
    cd ..
```
4. Build and install `bumblebee`:  
```
    cd bumblebee  
    ./bumblebee.Slackbuild  
    upgradepkg --install-new /tmp/bumblebee-<ver-arch-build>_bbsb.txz  
    cd ..  
```
5. Build and install `bbswitch` (Optional but recommended):  
```
    cd bbswitch  
    ./bbswitch.Slackbuild  
    upgradepkg --install-new /tmp/bbswitch-<ver-arch-build>_bbsb.txz  
    cd ..  
```
  - Note:
  This in an optional requirement.  This is the kernel module that allows 
  the Nvidia card to be turned off, potentially saving you power.  If you 
  do not need power management or the ability to turn off the nVidia chip, 
  you can skip this.
  - Note: This will need rebuilt when you upgrade the kernel.  
6. Build and install `primus`:  
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
7. Blacklist nouveau (or skip steps 8, 9, 10):  
```
    cd nouveau-blacklist
    upgradepkg xf86-video-nouveau-blacklist-noarch-1.txz
    cd ..
```
  - Note:
  This will blacklist / remove the conflicting nouveau driver from 
  slackware, it will however come back unless you add `xf86-video-nouveau`
  to `/etc/slackpkg/blacklist`  
8. Build and install `libvdpau` (Optional, not needed if using nouveau):  
```
    cd libvdpau  
    ./libvdpau.Slackbuild  
    upgradepkg --install-new /tmp/libvdpau-<ver-arch-build>_bbsb.txz  
    cd ..  
```
9. Build and install `nvidia-kernel` (Optional, not needed if using nouveau):  
```
    cd nvidia-kernel  
```
  For pure 32 or 64 bit systems, build via:
```
    ./nvidia-kernel.Slackbuild  
```
  If the system is x86_64 based, 32-bit compatible binaries and
  libraries can be built via:  
```
    COMPAT32=yes ./nvidia-kernel.SlackBuild  
```
  Then install:  
```
    upgradepkg --install-new /tmp/nvidia-kernel-<ver-arch-build>_bbsb.txz
    cd ..  
```
  - Note: This will need rebuilt when you upgrade the kernel.  
10. Build and install `nvidia-bumblebee` (Optional, not needed if using nouveau):  
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
11. Run the `rc.bumblebee` script:  
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
12. Reboot:  
  Not really a step, but you need to get all the new goodness started somehow.
13. Now an application can run with `primusrun`:  
```
    primusrun glxgears  
```
