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
CONFFILE="dmore-cpufreq.conf"
echo; echo "$(date) $CONFFILE"
if $BB [ -f /system/$CONFFILE ];then
    if $BB [ "`$BB grep 1 /system/$CONFFILE`" ]; then
        echo "max1100 found, setting..."
        echo 1 > /sys/devices/virtual/misc/semaphore_cpufreq/oc
        echo 1128000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

     elif $BB [ "`$BB grep 2 /system/$CONFFILE`" ]; then
        echo "max1200 found, setting..."
        echo 2 > /sys/devices/virtual/misc/semaphore_cpufreq/oc
        echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    elif $BB [ "`$BB grep 3 /system/$CONFFILE`" ]; then
        echo "max1300 found, setting..."
        echo 3 > /sys/devices/virtual/misc/semaphore_cpufreq/oc
        echo 1300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    elif $BB [ "`$BB grep 800 /system/$CONFFILE`" ]; then
        echo "max800 found, setting..."
        echo 800000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    else
        echo "using default 1Ghz maxfreq..."
        echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    fi
else
    echo "/system/$CONFFILE not found, no overclock, skipping..."
fi

# load cpufreq_stats module after oc has been en-/disabled
# sleep 1
# $BB insmod /lib/modules/cpufreq_stats.ko


# Default Read Ahead value for SD cards (mmcblk)
    echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb 
    echo 512 > /sys/block/mmcblk1/queue/read_ahead_kb 

echo;echo "modules:"
$BB lsmod

# Turn off debugging for certain modules
  echo 0 > /sys/module/wakelock/parameters/debug_mask
  echo 0 > /sys/module/userwakelock/parameters/debug_mask
  echo 0 > /sys/module/earlysuspend/parameters/debug_mask
  echo 0 > /sys/module/alarm/parameters/debug_mask
  echo 0 > /sys/module/alarm_dev/parameters/debug_mask
  echo 0 > /sys/module/binder/parameters/debug_mask


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
echo 10 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 2 > /proc/sys/net/ipv4/tcp_syn_retries
echo 2 > /proc/sys/net/ipv4/tcp_synack_retries

#-------------------------------------------------------------------------------
# init.d support, executes all <S>scriptname files
# inside /system/etc/init.d or /data/init.d directories
#-------------------------------------------------------------------------------
echo;echo "$(date) init.d/userinit.d"

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

echo $(date) USER INIT START from /data/init.d
if cd /data/init.d >/dev/null 2>&1 ; then
     for file in S* ; do
         if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
         echo "START '$file'"
         /system/bin/sh "$file"
         echo "EXIT '$file' ($?)"
     done
fi
echo $(date) USER INIT DONE from /data/init.d
    

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
