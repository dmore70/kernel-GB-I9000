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


# Default Read Ahead value for sdcards
    echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb 
    echo 512 > /sys/block/mmcblk1/queue/read_ahead_kb 

echo;echo "modules:"
$BB lsmod

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
