#!/sbin/sh
SETUPPATH=/tmp/rogue

# Unpack
mkdir $SETUPPATH/ramdisk/
mv $SETUPPATH/boot.img-ramdisk.gz $SETUPPATH/ramdisk/boot.img-ramdisk.gz
(cd $SETUPPATH/ramdisk/ && gzip -dc $SETUPPATH/ramdisk/boot.img-ramdisk.gz | cpio -i)
rm $SETUPPATH/ramdisk/boot.img-ramdisk.gz

# Unsecure image
sed -i "s|ro.secure=1|ro.secure=0|" $SETUPPATH/ramdisk/default.prop

# Modify stock init.stingray.rc
grep usbdisk $SETUPPATH/ramdisk/init.stingray.rc
if [ $? = 1 ]; then
    grep "/media/usb" $SETUPPATH/ramdisk/init.stingray.rc
fi

if [ $? = 1 ]; then
    sed -i "s|mkdir /mnt/sdcard 0000 system system|mkdir /mnt/sdcard 0000 system system\n    mkdir /mnt/usbdisk 0000 system system|" $SETUPPATH/ramdisk/init.stingray.rc
    sed -i "s|symlink /mnt/sdcard /sdcard|symlink /mnt/sdcard /sdcard\n    symlink /mnt/usbdisk /usbdisk|" $SETUPPATH/ramdisk/init.stingray.rc
    sed -i "s|mkdir /mnt/external1 0000 system system|mkdir /mnt/external1 0000 system system\n    symlink /mnt/external1 /sdcard2|" $SETUPPATH/ramdisk/init.stingray.rc
    
    sed -i "s|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/system /system wait ro|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/system /system wait ro noatime nodiratime|" $SETUPPATH/ramdisk/init.stingray.rc
    sed -i "s|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/userdata /data wait noatime nosuid nodev nomblk_io_submit|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/userdata /data wait nosuid nodev noatime nodiratime nomblk_io_submit,noauto_da_alloc|" $SETUPPATH/ramdisk/init.stingray.rc
    sed -i "s|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/cache /cache wait noatime nosuid nodev nomblk_io_submit|mount ext4 /dev/block/platform/sdhci-tegra.3/by-name/cache /cache wait nosuid nodev noatime nodiratime nomblk_io_submit,noauto_da_alloc|" $SETUPPATH/ramdisk/init.stingray.rc
fi

# Modify stock vold.fstab (USB OTG drives)
grep usbdisk /system/etc/vold.fstab
if [ $? = 1 ]; then
    grep "/media/usb" /system/etc/vold.fstab
fi

if [ $? = 1 ]; then
    echo "dev_mount usbdisk /mnt/usbdisk auto /devices/platform/tegra-ehci" >> /system/etc/vold.fstab
fi

# Modify stock init.rc (sysinit)
grep sysinit $SETUPPATH/ramdisk/init.rc
if [ $? = 1 ]; then
    sed -i "s|ioprio be 2|ioprio be 2\n\n# Run init.d scripts\nservice sysinit /system/bin/sysinit\n    class main\n    user root\n    oneshot\n|" $SETUPPATH/ramdisk/init.rc
    
    # Copy CM sysinit
    if [ ! -e /system/bin/sysinit ]; then
        cp sysinit /system/bin/sysinit
        chmod 755 /system/bin/sysinit
        chgrp 2000 /system/bin/sysinit
    fi
fi

# Repack
(cd $SETUPPATH/ramdisk/ && find . | cpio -o -H newc | gzip -9 > $SETUPPATH/newramdisk.gz)
echo \#!/sbin/sh > $SETUPPATH/createnewboot.sh
echo $SETUPPATH/mkbootimg --kernel $SETUPPATH/zImage --ramdisk $SETUPPATH/newramdisk.gz --cmdline \"$(cat $SETUPPATH/boot.img-cmdline)\" --base $(cat $SETUPPATH/boot.img-base) --output $SETUPPATH/newboot.img >> $SETUPPATH/createnewboot.sh
chmod 777 $SETUPPATH/createnewboot.sh
$SETUPPATH/createnewboot.sh
return $?
