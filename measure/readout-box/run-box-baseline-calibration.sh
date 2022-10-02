#! /usr/bin/env bash

ENA0="0xf"
ENA1="0xf"
ENA2="0xf"
ENA3="0xf"
ENA4="0xf"
ENA5="0xf"

BCRCONF="standard.310"
#BCRCONF="minus40c"

RANGE0="0"
RANGE1="0"
RANGE2="0"
RANGE3="0"
RANGE4="3"
RANGE5="3"

DATESTR="$(date +%Y%m%d-%H%M%S)"
DIR=/home/eic/DATA/baselineScan/${DATESTR}
mkdir -p $DIR

echo " ---"
echo " --- starting baseline calibration: $DIR "
echo " ---"

### HV must be ON with all DACs at zero
for I in {0..3}; do /au/masterlogic/zero $I; done
/au/tti/hv.on

### prepare to run bolognaScan
cat <<EOF > $DIR/readout.maxthreshold.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA0}	 0xb01b         ${BCRCONF}	maxthreshold
1	 ${ENA1}	 0xb01b 	${BCRCONF}	maxthreshold
2  	 ${ENA2}	 0xb01b 	${BCRCONF}	maxthreshold
3  	 ${ENA3}	 0xb01b 	${BCRCONF}	maxthreshold
4  	 ${ENA4}	 0xb01b 	${BCRCONF}	maxthreshold
5  	 ${ENA5}	 0xb01b 	${BCRCONF}	maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.maxthreshold.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR | tee $DIR/bolognaScan.log

### link PCR files 
ln -sf $DIR /au/conf/pcr/dcr-setup/.

cat <<EOF > $DIR/readout.range${RANGE}.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA0}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE0}
1	 ${ENA1}	 0xb01b         ${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip1.range${RANGE1}
2  	 ${ENA2}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip2.range${RANGE2}
3  	 ${ENA3}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip3.range${RANGE3}
4  	 ${ENA4}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip4.range${RANGE4}
5  	 ${ENA5}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip5.range${RANGE5}
# don't delete this line
EOF
ln -sf $DIR/readout.range${RANGE}.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

echo " ---"
echo " --- baseline calibration completed "
echo " ---"

