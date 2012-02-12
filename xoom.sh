#!/bin/sh

echo "copying config for the Xoom"
cp arch/arm/configs/stingray_defconfig .config

echo "building kernel"
make -j8

echo "launching packaging script"
./release/doit.sh
