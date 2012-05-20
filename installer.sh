#!/bin/sh

NUMJOBS=${NUMJOBS:--j4}

export BUILD=${BUILD:-1}
export TAG=${TAG:-_SBo}
export TMP=${TMP:-/tmp/SBo}
export OUTPUT=${OUTPUT:-/tmp}
export PKGTYPE=${PKGTYPE:-tgz}

PACKAGES=( \
  libjpeg-turbo \
  VirtualGL \
  libbsd \
  bumblebee \
  bbswitch \
  nvidia-bumblebee \
  nvidia-kernel \
)

CWD=$(pwd)

if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) ARCH=i486 ;;
    arm*) ARCH=arm ;;
       *) ARCH=$( uname -m ) ;;
  esac
fi

add_rc_d()
{
  if grep -q "$2" "$1"; then
    return
  fi
  
  if ! [ -e "$1" ]; then
    echo -e "#/bin/sh\n" > $1
  fi
  
  if ! [ -x "$1" ]; then
    chmod a+x "$1"
  fi
  
  (
    if [ -n "$(tail -n 1 $1)" ]; then
      echo ""
    fi
    
    echo "if [ -x $2 ]; then"
    echo "  $2 $3"
    echo "fi"
    echo ""
  ) >> "$1"
}

del_rc_d()
{
  line=$(grep -nm 1 "$2 $3" "$1" 2>/dev/null | cut -d : -f 1)
  
  if [ -z "$line" ]; then
    return
  fi
  
  sed -i "$(($line - 1)),$(($line + 2))d" "$1"
}

download()
{
  for url in $@ ; do
    file=$(basename $url)
    path=$(find $CWD -type f -name $file | head -n 1)
    
    if [ -n "$path" ]; then
      if ! [ -e "$file" ]; then
        ln -sf "$path"
      fi
      
      continue
    fi
    
    len=$(wget --spider $url 2>&1 | grep Length | cut -d ' ' -f 2)
    
    if [ -z "$len" ]; then
      len=$(wget --spider $url 2>&1 | grep SIZE | rev | cut -d ' ' -f 1 | rev)
    fi
    
    wget -O "$file" "$url" 2>/dev/null &
    pid=""
    
    (
      while kill -0 "$pid" &>/dev/null; do
        size=$(stat -c %s $file 2>/dev/null || echo "0")
        prog=$(echo "($size / $len) * 100" | bc -l | xargs printf %1.0f)
        
        echo "XXX"
        echo "$prog"
        echo "\n$file\n\n"
        echo "Total size: $len B"
        echo "Downloaded: $size B"
        echo "XXX"
        
        sleep 1
      done
    ) |
    dialog \
      --title "Package Download" \
      --gauge "\n$file" 11 47
    
    dialog \
      --title   "Package Download" \
      --infobox "\nDownloaded: $file" 5 47
    
    sleep 2
  done
}

menu()
{
  reply=$(dialog \
    --title "Bumblebee Interactive Installer" \
    --menu  "\nWelcome to the Bumblebee interactive installer.\n\
             \nWhat would you like to do?\n" 12 52 3 \
      "Install" "Install the Bumblebee packages" \
      "Remove"  "Remove the Bumblebee packages" \
      "Exit"    "Exit the interactive installer" \
   3>&1 1>&2 2>&3)
   
   case "$reply" in
    Install)
      install
      ;;
    Remove)
      remove
      ;;
    *)
      dialog --clear
      exit
      ;;
  esac
}

install()
{
  if ! getent group bumblebee 1>/dev/null; then
    dialog \
      --title "Bumblebee Group Creation" \
      --yesno "\nA bumblebee group is required, would you like to create one?" \
        7 64
    
    if [ "$?" != "0" ]; then
      dialog \
        --title  "Bumblebee Group Creation" \
        --msgbox "\nA bumblebee group is required to proceed" 7 44
      
      menu
      return;
    fi
    
    groupadd -g 261 bumblebee
    
    if [ "$?" = "0" ]; then
      dialog \
        --title  "Bumblebee Group Creation" \
        --msgbox "\nA bumblebee group was created" 7 33
    else
      dialog \
        --title  "Bumblebee Group Creation" \
        --msgbox "\nFailed to create the bumblebee group" 7 40
    fi
  fi
  
  if [ "$ARCH" = "x86_64" ]; then
    dialog \
      --title "Multilib Support" \
      --yesno "\nThis system appears to be x86_64 based. Several of the\
               \nbumblebee dependencies can be multilib enabled allowing\
               \nfor compatability with 32-bit binaries.\n\
               \nWould you like to enable multilib support?" 11 59
    
    if [ "$?" = "0" ]; then
      export COMPAT32="yes"
    fi
  fi
  
  pkgs=()
  
  for pkg in ${PACKAGES[@]}; do
    source "$CWD/$pkg/$pkg.info"
    
    if [ -n "$(ls /var/log/packages/$pkg-* 2>/dev/null)" ]; then
      state="off"
    else
      state="on"
    fi
    
    desc=$(cat $CWD/$pkg/slack-desc | grep -m 1 "^$pkg:")
    desc=$(echo $desc | sed 's/.* (\(.*\))/\1/')
    
    pkgs+=("$pkg" "$desc" "$state")
  done
  
  reply=$(dialog --separate-output \
    --title     "Installation Selection" \
    --checklist "\nWhich packages would you like to install?" 15 67 7 \
    "${pkgs[@]}" \
   3>&1 1>&2 2>&3)
  
  if [ -z "$reply" -o "$?" != "0" ]; then
    menu
    return
  fi
  
  for pkg in $reply; do
    cd     "$CWD/$pkg"
    source "$pkg.info"
    
    if [ "$pkg" = "nvidia-bumblebee" -a "$ARCH" = "x86_64" ]; then
      download $(echo $DOWNLOAD | cut -d ' ' -f 2-)
    fi
    
    if [ -n "$DOWNLOAD_x86_64" -a "$ARCH" = "x86_64" ]; then
      download "$DOWNLOAD_x86_64"
    else
      download "$DOWNLOAD"
    fi
    
    desc=$(cat $CWD/$pkg/slack-desc | grep "^$pkg:" | sed "s/^$pkg:\s*//")
    
    dialog --cr-wrap \
      --title   "Building Package" \
      --infobox "\nStep 1 of 2: Building $pkg\n\n$desc" 16 75
    
    MAKEFLAGS="$NUMJOBS" \
    sh $pkg.SlackBuild &>/dev/null
    
    if [ "$?" != "0" ]; then
      dialog \
        --title "Building Package" \
        --yesno "\nFailed to build $pkg\n\
                 \nDo you wish to continue?" 0 0
      
      if [ "$?" != "0" ]; then
        menu
        return
      fi
    fi
    
    dialog --cr-wrap \
      --title   "Installing Package" \
      --infobox "\nStep 2 of 2: Installing $pkg\n\n$desc" 16 75
    
    upgradepkg \
      --install-new \
      --reinstall \
     $OUTPUT/$PRGNAM-$VERSION-$ARCH-$BUILD$TAG.$PKGTYPE &>/dev/null
    
    if [ "$?" != "0" ]; then
      dialog \
        --title "Installing Package" \
        --yesno "\nFailed to install $pkg\n\
                 \nDo you wish to continue?" 0 0
      
      if [ "$?" != "0" ]; then
        menu
        return
      fi
    fi
  done
  
  if echo "$reply" | grep -q bumblebee; then
    if ! grep -q rc.bumblebeed /etc/rc.d/rc.local ||
       ! grep -q rc.bumblebeed /etc/rc.d/rc.local_shutdown; then
      dialog \
        --title "Automatic Starting and Stopping" \
        --yesno "\nBumblebee requires a daemon (bumblebeed) to run in the\
                 \nbackground. For bumblebebeed to be automatically started\
                 \nand stopped with your system, the rc script (rc.bumblebeed)\
                 \nmust be added to rc.local and rc.local_shutdown.\n
                 \nWould you like to automatically start and stop bumblebeed?" \
                 11 65
      
      if [ "$?" = "0" ]; then
        add_rc_d /etc/rc.d/rc.local          /etc/rc.d/rc.bumblebeed start
        add_rc_d /etc/rc.d/rc.local_shutdown /etc/rc.d/rc.bumblebeed stop
        
        chmod a+x /etc/rc.d/rc.bumblebeed
      fi
    fi
  fi
  
  dialog \
    --title "Installation Complete" \
    --yesno "\nBumblebee and its related packages have been installed!\n\
             \nDo not forget to add users to the bumblebee group. Any\
             \nuses that need bumblebee access must be in the bumblebee\
             \ngroup. You can add users to the bumblebee group via:\n\
             \n  # usermod -G bumblebee -a USERNAME\n\n\
             \nWould you like to start the bumblebee daemon now?" 16 60
  
  if [ "$?" = "0" ]; then
    sh /etc/rc.d/rc.bumblebeed start &>/dev/null
    
    if [ "$?" = "0" ]; then
      dialog \
        --title  "Bumblebee Daemon" \
        --msgbox "\nThe bumblebee daemon has been started!\n\
                  \nYou can now test bumblebee with glxgears:\n\
                  \n  # optirun glxgears" 11 45
    else
      dialog \
        --title  "Bumblebee Daemon" \
        --msgbox "\nThe bumblebee daemon failed to start" 7 40
    fi
  fi
  
  menu
}

remove()
{
  pkgs=()
  
  for pkg in ${PACKAGES[@]}; do
    file=$(find /var/log/packages -type f -name $pkg-* | head -n 1)
    
    if [ -n "$file" ]; then
      desc=$(cat $file | grep -m 1 "^$pkg:")
      desc=$(echo $desc | sed 's/.* (\(.*\))/\1/')
      
      pkgs+=("$pkg" "$desc" "on")
    fi
  done
  
  reply=$(dialog --separate-output \
    --title     "Removal Selection" \
    --checklist "\nWhich packages would you like to remove?" 15 67 7 \
    "${pkgs[@]}" \
   3>&1 1>&2 2>&3)
  
  if [ -z "$reply" -o "$?" != "0" ]; then
    menu
    return
  fi
  
  for pkg in $reply; do
    dialog \
      --title   "Removing Package" \
      --infobox "\nRemoving $pkg" 5 0
    
    removepkg "$pkg" &>/dev/null
    
    if [ "$?" != "0" ]; then
      dialog \
      --title  "Removing Package" \
      --msgbox "\nFailed to remove $pkg" 7 0
      
      continue
    fi
  done
  
  if echo "$reply" | grep -q bumblebee; then
    del_rc_d /etc/rc.d/rc.local          /etc/rc.d/rc.bumblebeed start
    del_rc_d /etc/rc.d/rc.local_shutdown /etc/rc.d/rc.bumblebeed stop
    
    rm -f \
      /etc/bumblebee/bumblebee.conf \
      /etc/rc.d/rc.bumblebeed
    
    rmdir --ignore-fail-on-non-empty /etc/bumblebee
  fi
  
  dialog \
    --title  "Removal Complete" \
    --msgbox "\nAll selected packages, configuration, and rc scripts\
              \nhave been removed from the system" 8 56
  
  menu
}

if [ "$UID" != "0" ]; then
  dialog \
    --title  "Insufficient Permission" \
    --msgbox "\nThis script must be run as root" 7 35
  
  exit 1
fi

menu
