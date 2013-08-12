# set busybox location
BB="/sbin/busybox"

cat_msg_sysfile() {
    MSG=$1
    SYSFILE=$2
    echo -n "$MSG"
    cat $SYSFILE
}

#-------------------------------------------------------------------------------
# initialize some stuff
#-------------------------------------------------------------------------------
STL=`ls -d /sys/block/stl*`
BML=`ls -d /sys/block/bml*`
MMC=`ls -d /sys/block/mmc*`
TFSR=`ls -d /sys/block/tfsr*`
$BB mount -t rootfs -o remount,rw rootfs

# rp_filter must be reset to 0 only if TUN module is used (issues)
# so initialize it with '1' *before* module parsing
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter

#-------------------------------------------------------------------------------
# partitions
#-------------------------------------------------------------------------------
echo "$(date) mount"
for k in $($BB mount | $BB grep relatime | $BB cut -d " " -f3)
do
    sync
    $BB mount -o remount,noatime,nodiratime $k
done
echo "trying to remount EXT4 partitions with speed tweaks if any..."
for k in $($BB mount | $BB grep ext4 | $BB cut -d " " -f3)
do
  sync;
  if $BB [ "$k" = "/system" ]; then
    $BB mount -o remount,noauto_da_alloc,barrier=0,commit=40 $k;
  elif $BB [ "$k" = "/dbdata" ]; then
    $BB mount -o remount,noauto_da_alloc,barrier=1,nodelalloc,commit=40 $k;
  elif $BB [ "$k" = "/data" ]; then
    $BB mount -o remount,noauto_da_alloc,barrier=1,commit=40 $k;
  elif $BB [ "$k" = "/cache" ]; then
    $BB mount -o remount,noauto_da_alloc,barrier=0,commit=40 $k;
  fi;
done

$BB mount|grep /system
$BB mount|grep /data
$BB mount|grep /dbdata
$BB mount|grep /cache

#-------------------------------------------------------------------------------
# CPU maxfreq
#-------------------------------------------------------------------------------
CONFFILE="midnight_freq.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /data/local/$CONFFILE ];then
    if $BB [ "`$BB grep 1128 /data/local/$CONFFILE`" ]; then
        echo "oc1128 found, setting..."
        echo 1 > /sys/devices/virtual/misc/midnight_cpufreq/oc1128
        echo 1128000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    elif $BB [ "`$BB grep 800 /data/local/$CONFFILE`" ]; then
        echo "max800 found, setting..."
        echo 800000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    else
        echo "using default 1Ghz maxfreq..."
        echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi

# load cpufreq_stats module after oc has been en-/disabled
sleep 1
$BB insmod /lib/modules/cpufreq_stats.ko

#-------------------------------------------------------------------------------
# CPU governor
#-------------------------------------------------------------------------------
CONFFILE="midnight_gov.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /data/local/$CONFFILE ];then
    if $BB [[ "`$BB grep conservative /data/local/$CONFFILE`" || "`$BB grep ondemand /data/local/$CONFFILE`" || "`$BB grep smartassV2 /data/local/$CONFFILE`" || "`$BB grep smoove /data/local/$CONFFILE`" ]]; then
        echo "valid governor found, setting..."
        echo $($BB head -n 1 /data/local/$CONFFILE) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi

#-------------------------------------------------------------------------------
# misc kernel options
#-------------------------------------------------------------------------------
CONFFILE="midnight_options.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /data/local/$CONFFILE ];then

    # sdcard read_ahead
    if $BB [ "`$BB grep 512 /data/local/$CONFFILE`" ]; then
        echo "readahead 512Kb found, setting..."
        echo 512 > /sys/devices/virtual/bdi/179:0/read_ahead_kb
        echo 512 > /sys/devices/virtual/bdi/179:8/read_ahead_kb
    fi

    # IO scheduler
    if $BB [ "`$BB grep NOOP /data/local/$CONFFILE`" ]; then
        echo "NOOP scheduler found, setting..."
        for i in $STL $BML $MMC $TFSR;do
            echo "$iosched" > $i/queue/scheduler
        done
    fi

    # enable BTHID module loading 
    if $BB [ "`$BB grep BTHID /data/local/$CONFFILE`" ]; then
      echo "MISC: loading bthid.ko..."
      insmod /lib/modules/bthid.ko
    fi

    # enable TUN module loading 
    if $BB [ "`$BB grep TUN /data/local/$CONFFILE`" ]; then
      echo "MISC: loading tun.ko..."
      insmod /lib/modules/tun.ko
      echo "MISC: disabling IPv4 rp_filter for VPN..."
      echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
    fi

    # LED timeout 
    if $BB [ "`$BB grep LEDTIMEOUT /data/local/$CONFFILE`" ]; then
        echo 250 > /sys/class/misc/backlightnotification/timeout
        echo -n "LED timeout: ";cat /sys/class/misc/backlightnotification/timeout
    fi
    
    # touchscreen sensitivity 
    if $BB [ "`$BB grep TOUCHSCREEN /data/local/$CONFFILE`" ]; then
        echo "setting enhanced touchscreen sensitivity..."
        echo 7027 > /sys/class/touch/switch/set_touchscreen
        echo 8001 > /sys/class/touch/switch/set_touchscreen
        echo 11001 > /sys/class/touch/switch/set_touchscreen
        echo 13030 > /sys/class/touch/switch/set_touchscreen   
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi

echo;echo "modules:"
$BB lsmod

#-------------------------------------------------------------------------------
# undervolting profiles
#-------------------------------------------------------------------------------
CONFFILE="midnight_uv.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /data/local/$CONFFILE ];then
    # set uv values
    if $BB [ "`$BB grep UV1 /data/local/$CONFFILE`" ]; then
        echo "UV1 found, setting..."
        echo 0 0 25 50 75 > /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
    elif $BB [ "`$BB grep UV2 /data/local/$CONFFILE`" ]; then
        echo "UV2 found, setting..."
        echo 0 0 25 75 100 > /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
    elif $BB [ "`$BB grep UV3 /data/local/$CONFFILE`" ]; then
        echo "UV3 found, setting..."
        echo 0 0 50 75 125 > /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
    else
        echo "using default values (no undervolting)..."
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi

cat_msg_sysfile "max           : " /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
cat_msg_sysfile "gov           : " /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat_msg_sysfile "UV_mv         : " /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
cat_msg_sysfile "states_enabled: " /sys/devices/system/cpu/cpu0/cpufreq/states_enabled_table
echo
echo "freq/voltage  : ";cat /sys/devices/system/cpu/cpu0/cpufreq/frequency_voltage_table
echo

#-------------------------------------------------------------------------------
# gamma
#-------------------------------------------------------------------------------
CONFFILE="midnight_gamma.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /data/local/$CONFFILE ];then
    if $BB [ "`$BB grep GAM1 /data/local/$CONFFILE`" ]; then
        echo "GAM1 found, setting..."
        echo 1 > /sys/devices/virtual/misc/rgbb_multiplier/gamma
    elif $BB [ "`$BB grep GAM3 /data/local/$CONFFILE`" ]; then
        echo "GAM3 found, setting..."
        echo 11 > /sys/devices/virtual/misc/rgbb_multiplier/gamma
    else
        echo "using default values..."
        echo 7 > /sys/devices/virtual/misc/rgbb_multiplier/gamma
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi

#-------------------------------------------------------------------------------
# rgb
#-------------------------------------------------------------------------------
#<string name="r">1887492806</string>
#<string name="g">2169824215</string>
#<string name="b">3209991042</string>       
CONFFILE="midnight_rgb.conf"
echo; echo "$(date) $CONFFILE"
echo "rgb original:"
cat /sys/devices/virtual/misc/rgbb_multiplier/red_multiplier
cat /sys/devices/virtual/misc/rgbb_multiplier/green_multiplier
cat /sys/devices/virtual/misc/rgbb_multiplier/blue_multiplier
if $BB [ -f /data/local/$CONFFILE ];then
    if $BB [ "`$BB grep RGB2 /data/local/$CONFFILE`" ]; then
        echo "RGB2 found, setting..."
        echo 1837492806 > /sys/devices/virtual/misc/rgbb_multiplier/red_multiplier
        echo 2019824215 > /sys/devices/virtual/misc/rgbb_multiplier/green_multiplier
        echo 3209991042 > /sys/devices/virtual/misc/rgbb_multiplier/blue_multiplier
    elif $BB [ "`$BB grep RGB3 /data/local/$CONFFILE`" ]; then
        echo "RGB3 found, setting..."
        echo 1737492806 > /sys/devices/virtual/misc/rgbb_multiplier/red_multiplier
        echo 2119824215 > /sys/devices/virtual/misc/rgbb_multiplier/green_multiplier
        echo 3209991042 > /sys/devices/virtual/misc/rgbb_multiplier/blue_multiplier
    else
        echo 1887492806 > /sys/devices/virtual/misc/rgbb_multiplier/red_multiplier
        echo 2169824215 > /sys/devices/virtual/misc/rgbb_multiplier/green_multiplier
        echo 3209991042 > /sys/devices/virtual/misc/rgbb_multiplier/blue_multiplier
        echo "using default values..."
    fi
else
    echo "/data/local/$CONFFILE not found, skipping..."
fi
echo "rgb new:"
cat /sys/devices/virtual/misc/rgbb_multiplier/red_multiplier
cat /sys/devices/virtual/misc/rgbb_multiplier/green_multiplier
cat /sys/devices/virtual/misc/rgbb_multiplier/blue_multiplier        


#-------------------------------------------------------------------------------
# security
#-------------------------------------------------------------------------------
echo; echo "$(date) sec"
echo 0 > /proc/sys/net/ipv4/ip_forward
echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
cat_msg_sysfile "SEC: ip_forward :" /proc/sys/net/ipv4/ip_forward
cat_msg_sysfile "SEC: rp_filter :" /proc/sys/net/ipv4/conf/all/rp_filter
cat_msg_sysfile "SEC: use_tempaddr :" /proc/sys/net/ipv6/conf/all/use_tempaddr
cat_msg_sysfile "SEC: accept_source_route :" /proc/sys/net/ipv4/conf/all/accept_source_route
cat_msg_sysfile "SEC: send_redirects :" /proc/sys/net/ipv4/conf/all/send_redirects
cat_msg_sysfile "SEC: icmp_echo_ignore_broadcasts :" /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 

#-------------------------------------------------------------------------------
# IPv4/TCP
#-------------------------------------------------------------------------------
echo; echo "$(date) ipv4/tcp"
echo "TCP: setting ipv4/tcp tweaks..."
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 > /proc/sys/net/ipv4/tcp_sack
echo 1 > /proc/sys/net/ipv4/tcp_dsack
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 0 > /proc/sys/net/ipv4/tcp_timestamps




#-------------------------------------------------------------------------------
# mem info
#-------------------------------------------------------------------------------
echo   
echo "RAM (/proc/meminfo):"
cat /proc/meminfo|grep ^MemTotal
cat /proc/meminfo|grep ^MemFree
cat /proc/meminfo|grep ^Buffers
cat /proc/meminfo|grep ^Cached

#-------------------------------------------------------------------------------
# init.d support, executes all /system/etc/init.d/<S>scriptname files
#-------------------------------------------------------------------------------
echo;echo "$(date) init.d/userinit.d"
CONFFILE="midnight_options.conf"
if $BB [ -f /data/local/$CONFFILE ];then
    echo "configfile /data/local/midnight_options.conf found, checking values..."
    if $BB [ "`$BB grep INITD /data/local/$CONFFILE`" ]; then
        echo $(date) USER INIT START from /system/etc/init.d
        if cd /system/etc/init.d >/dev/null 2>&1 ; then
            for file in S* ; do
                if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
                echo "/system/etc/init.d: START '$file'"
                /system/bin/sh "$file"
                echo "/system/etc/init.d: EXIT '$file' ($?)"
            done
        fi
        echo $(date) USER INIT DONE from /system/etc/init.d
    else
        echo "init.d execution deactivated, nothing to do."
    fi
else
    echo "/data/local/midnight_options.conf not found, no init.d execution, skipping..."
fi

#-------------------------------------------------------------------------------
# CLEANUP
#-------------------------------------------------------------------------------
echo
echo "disabling /sbin/busybox, using /system/xbin/busybox now..."
/sbin/busybox_disabled rm /sbin/busybox

echo "removing unneeded initramfs stuff..."
/sbin/busybox_disabled rm -rf /res/misc

echo "mounting rootfs readonly..."
/sbin/busybox_disabled mount -t rootfs -o remount,ro rootfs;
