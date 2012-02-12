#!/bin/sh

[[ -d release ]] || {
	echo "must be in kernel root dir"
	exit 1;
}

echo "packaging up the kernel & modules"

TYPE=$1
[[ "$TYPE" == '' ]] && TYPE=Xoom

RELVER=$2
[[ "$RELVER" == '' ]] && RELVER="r6"

REL=ICS_${TYPE}_$(date +%Y%m%d)_Platypus_for_Xoom_${RELVER}.zip

echo "removing old kernel modules"
rm release/system/lib/modules/*
echo "				"
### rm -r release/system 2> /dev/null
#mkdir  -p release/system/bin || exit 1
#mkdir  -p release/system/lib/modules || exit 1
#mkdir  -p release/system/lib/hw || exit 1
#mkdir  -p release/system/etc/init.d || exit 1
#cp release/logger.module release/system/lib/modules/logger.ko

echo "copying over new kernel modules"
find . -name "*.ko" -exec cp {} release/system/lib/modules/ \; 2>/dev/null || exit 1
echo "				"

echo "removing old kernel"
rm release/installer/zImage
echo "				"

echo "now in fact putting all in a cwm zip-package"
cd release && {
#	cp 91logger system/etc/init.d/ || exit 1
#	cp S98system_tweak system/etc/init.d/ || exit 1
#	cp 98crunchengine system/etc/init.d/ || exit 1
#	cp S70zipalign system/etc/init.d/ || exit 1
#	cp lights.aries.so system/lib/hw/ || exit 1
#        cp lights.aries.so.BLN system/lib/hw/lights.aries.so || exit 1
#	mkdir -p system/bin
#	cp bin/rild_old system/bin/rild
#	cp libril.so_old system/lib/libril.so
#	cp libsecril-client.so_old system/lib/libsecril-client.so
	zip -q -r ${REL} system META-INF installer || exit 1
	sha256sum ${REL} > ${REL}.sha256sum
	rm -rf ${TYPE} || exit 1
	mkdir -p ${TYPE} || exit 1
	mv ${REL}* ${TYPE} || exit 1
} || exit 1

echo ${REL}
echo "done ..."
echo "				"
echo "removing kernel modules & kernel"
rm system/lib/modules/*
rm installer/zImage
##rm system/lib/hw/*
##rm system/etc/init.d/*
##rm system/bin/*
exit 0
