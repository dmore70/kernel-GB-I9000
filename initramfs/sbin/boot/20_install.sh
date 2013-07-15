clean_all_previous()
{
	/sbin/busybox rm /system/app/Semaphore.apk
	/sbin/busybox rm /data/dalvik-cache/*semaphore.apk*
	/sbin/busybox rm -r /data/cfroot
	/sbin/busybox rm -r /data/fproot
	/sbin/busybox rm -r /system/cfroot
	/sbin/busybox rm -r /system/fproot/sema*
}


echo "remounting /system readwrite..."
/sbin/busybox mount -o remount,rw /system

# create xbin
if /sbin/busybox [ -d /system/xbin ];then
    echo "/system/xbin found, skipping mkdir..."
else
    echo "/system/xbin not found, creating..."
    /sbin/busybox mkdir /system/xbin
    /sbin/busybox chmod 755 /system/xbin
fi

# create init.d
if /sbin/busybox [ -d /system/etc/init.d ];then
    echo "/system/etc/init.d found, skipping mkdir..."
else
    echo "/system/etc/init.d not found, creating..."
    /sbin/busybox mkdir /system/etc/init.d
    /sbin/busybox chmod 777 /system/etc/init.d
fi

# clean multiple su binaries
echo "cleaning su installations except /system/xbin/su if any..."
/sbin/busybox rm /system/bin/su
/sbin/busybox rm /vendor/bin/su
/sbin/busybox rm /system/sbin/su
/sbin/busybox rm /system/xbin/su

# clean  semaphore or cfroot files
clean_all_previous

# install xbin/su if not there
if /sbin/busybox [ -f /system/xbin/su ];then
    echo "/system/xbin/su found, skipping..."
else
    echo "cleaning up su installations..."
    echo "installing /system/xbin/su..."
    echo "if this fails free some space on /system."
    /sbin/busybox cat /res/misc/su > /system/xbin/su
    /sbin/busybox chown 0.0 /system/xbin/su
    /sbin/busybox chmod 4755 /system/xbin/su
fi

# remove SuperSU.apk if there
if /sbin/busybox [ -f /data/app/SuperSU.apk ]; then 
       echo "remove SuperSU.apk if present..."
       /sbin/busybox rm /system/app/SuperSU.apk
       /sbin/busybox rm /data/app/eu.chainfire.supersu*
       /sbin/busybox rm -r /data/data/eu.chainfire.supersu
       /sbin/busybox rm -r /data/dalvik-cache/system@app@SuperSU.apk@classes.dex
       /sbin/busybox rm /data/dalvik-cache/data@app@eu.chainfire.supersu-1.apk@classes.dex
fi

# install /system/app/Superuser.apk if not there
if /sbin/busybox [ -f /system/app/Superuser.apk ]; then
    echo "/system/app/Superuser.apk found, skipping..."
else
    echo "cleaning up Superuser.apk installations..."
    /sbin/busybox rm /system/app/Superuser.apk
    /sbin/busybox rm /data/app/Superuser.apk
    /sbin/busybox rm /system/app/com.noshufou.android.su*.apk
    /sbin/busybox rm /data/app/com.noshufou.android.su*.apk
    /sbin/busybox rm -r /data/data/com.noshufou.android.su*
    /sbin/busybox rm /system/app/SuperSU.apk
    /sbin/busybox rm /data/app/eu.chainfire.supersu*
    /sbin/busybox rm -r /data/data/eu.chainfire.supersu
    /sbin/busybox rm /data/dalvik-cache/system@app@SuperSU.apk@classes.dex
    /sbin/busybox rm /data/dalvik-cache/system@app@Superuser.apk@classes.dex
    /sbin/busybox rm /data/dalvik-cache/data@app@eu.chainfire.supersu-1.apk@classes.dex
    /sbin/busybox rm /data/dalvik-cache/data@app@com.noshufou.android.su-1.apk@classes.dex
    echo "installing /system/app/Superuser.apk"
    echo "if this fails free some space on /system."
    /sbin/busybox cat /res/misc/Superuser.apk > /system/app/Superuser.apk
    /sbin/busybox chown 0.0 /system/app/Superuser.apk
    /sbin/busybox chmod 644 /system/app/Superuser.apk
fi


echo "checking /data/local/logger.ko (Logcat)..."
if /sbin/busybox [ -f /data/local/logger.ko ];then
    echo "Logcat enabled, copying logger.ko..."
    cat /lib/modules/logger.ko > /data/local/logger.ko
fi

echo "remounting /system readonly..."
/sbin/busybox mount -o remount,ro /system
