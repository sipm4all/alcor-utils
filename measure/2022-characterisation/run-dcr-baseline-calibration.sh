#! /usr/bin/env bash

DATESTR="$(date +%Y%m%d-%H%M%S)"
DIR=/home/eic/DATA/baselineScan/${DATESTR}
mkdir -p $DIR

echo " ---"
echo " --- starting baseline calibration: $DIR "
echo " ---"

### switch off HV
/au/tti/hv.off

### prepare to run bolognaScan
cat <<EOF > $DIR/readout.maxthreshold.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 0x0 		 0xb01b 	minus40c	maxthreshold
1	 0x0 		 0xb01b 	minus40c	maxthreshold
2  	 0xf 		 0xb01b 	minus40c	maxthreshold
3  	 0xf		 0xb01b 	minus40c	maxthreshold
4  	 0x0 		 0xb01b 	plus20c		maxthreshold
5  	 0x0 		 0xb01b 	plus20c		maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.maxthreshold.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR | tee $DIR/bolognaScan.log

### link PCR files 
ln -sf $DIR /au/conf/pcr/dcr-setup/.

cat <<EOF > $DIR/readout.range1.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 0x0 		 0xb01b 	minus40c	dcr-setup/${DATESTR}/PCR/chip0.range1
1	 0x0 		 0xb01b 	minus40c	dcr-setup/${DATESTR}/PCR/chip1.range1
2  	 0xf 		 0xb01b 	minus40c	dcr-setup/${DATESTR}/PCR/chip2.range1
3  	 0xf		 0xb01b 	minus40c	dcr-setup/${DATESTR}/PCR/chip3.range1
4  	 0x0 		 0xb01b 	plus20c		maxthreshold
5  	 0x0 		 0xb01b 	plus20c		maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.range1.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

echo " ---"
echo " --- baseline calibration completed "
echo " ---"

