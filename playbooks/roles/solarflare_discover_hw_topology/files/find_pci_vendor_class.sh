#!/bin/bash

#set -x
set -e

PCI_DEVICES=/sys/bus/pci/devices

cd ${PCI_DEVICES}

VENDOR_ID=$1
CLASS_ID=$2
OUTFILE=$3

if [ -e ${OUTFILE} ]; then
    rm ${OUTFILE}
fi

for i in `ls ${PCI_DEVICES}`
do
    VENDOR=`cat $i/vendor`
    CLASS=`cat $i/class`

    if [ $(( ${VENDOR} ^ ${VENDOR_ID} )) == 0 ]; then
        if [ $(( ${CLASS} ^ ${CLASS_ID} )) == 0 ]; then
            echo $i >> ${OUTFILE}
        fi

    fi
done

