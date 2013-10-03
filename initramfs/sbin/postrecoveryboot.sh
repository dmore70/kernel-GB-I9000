#!/sbin/busybox sh

/sbin/busybox rm /etc
/sbin/busybox mkdir /etc
cat /res/etc/recovery.fstab > /etc/recovery.fstab

/sbin/busybox rm /sdcard
/sbin/busybox mkdir /sdcard
/sbin/busybox mount -t vfat -o noatime,nodiratime /dev/block/mmcblk0p1 /sdcard >> /dev/null 2>&1
/sbin/busybox mount -t ext4 -o noatime,nodiratime,noauto_da_alloc,barrier=1 /dev/block/mmcblk0p1 /sdcard >> /dev/null 2>&1

/sbin/busybox rmdir /sdcard/external_sd
/sbin/busybox mkdir /sdcard/external_sd
/sbin/busybox mount -t vfat /dev/block/mmcblk1p1 /sdcard/external_sd

/sbin/busybox rm -rf /sdcard/.android_secure
if [ -d /sdcard/external_sd/.android_secure ];
then
  /sbin/busybox mkdir /sdcard/.android_secure
  /sbin/busybox mount --bind /sdcard/external_sd/.android_secure /sdcard/.android_secure
fi;

FILES=$(find /sdcard/clockworkmod/backup -name boot.img);
for FILE in $FILES; do
  FILESIZE=$(stat -t $FILE | cut -d " " -f 2)
  if [ "$FILESIZE" -le "4096" ];
  then
    DIR=$(dirname $FILE);
    $(rm $DIR/boot.img);
    $(rm $DIR/recovery.img);
    $(cat $DIR/nandroid.md5 | grep -v boot.img | grep -v r > $DIR/nandroid.md5);
  fi;
done

/sbin/busybox umount /dbdata
