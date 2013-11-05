echo "Checking su and Superuser ....."

install_su()
{          
        echo "Install (su) and (superser)"  
	/sbin/busybox mount -o remount,rw / /
	/sbin/busybox mount -o remount,rw /system

	/sbin/busybox rm /system/xbin/su
	/sbin/busybox rm /system/app/Superuser*.apk
	/sbin/busybox rm /data/app/Superuser*.apk
	/sbin/busybox rm /system/app/com.noshufou.android.su*.apk
	/sbin/busybox rm /data/app/com.noshufou.android.su*.apk
	/sbin/busybox rm -r /data/data/com.noshufou.android.su*
	/sbin/busybox cp /res/misc/su /system/xbin/su
	/sbin/busybox cp /res/misc/Superuser.apk /system/app/Superuser.apk
	/sbin/busybox chown 0.0 /system/xbin/su
	/sbin/busybox chmod 6755 /system/xbin/su
	/sbin/busybox rm -r /system/fproot
         /sbin/busybox rm -r /system/cfroot
	/sbin/busybox rm -r /data/cfroot
	/sbin/busybox rm -r /data/fproot
	/sbin/busybox rm /system/app/Semaphore.apk
	/sbin/busybox rm /data/dalvik-cache/*semaphore.apk*

	
	/sbin/busybox mount -o remount,ro / /
	/sbin/busybox mount -o remount,ro /system
}

install_initd()
{
	/sbin/busybox mkdir /system/etc/init.d
	/sbin/busybox chmod 777 /system/etc/init.d
}

clean_all()
{
        echo "Clean possible previous Semaphore or Chainfire admin files"
	/sbin/busybox rm /system/app/Semaphore.apk
	/sbin/busybox rm /data/dalvik-cache/*semaphore.apk*
	/sbin/busybox rm -r /data/cfroot
	/sbin/busybox rm -r /data/fproot
	/sbin/busybox rm -r /system/cfroot
	/sbin/busybox rm -r /system/fproot/sema*
}

if /sbin/busybox test -u /system/xbin/su && /sbin/busybox test -f /system/app/Superuser.apk; then
        echo "Superuser.apk and su binary have been found"
	/sbin/busybox mount -o remount,rw / /
	/sbin/busybox mount -o remount,rw /system
	clean_all
	install_initd
	/sbin/busybox mount -o remount,ro / /
	/sbin/busybox mount -o remount,ro /system

	if /sbin/busybox test /res/misc/su -nt /system/xbin/su; then
          echo "(su) binary file inside initramfs dmore.kernel is newer than ROM's su;  so i install it"
	  install_su
	elif /sbin/busybox test /res/misc/Superuser.apk -nt /system/app/Superuser.apk; then
          echo "Superuser.apk inside initramfs dmore.kernel is newer than ROM's Superuser.apk;  so i install it"
	  install_su
	fi;
else	install_su

fi;

