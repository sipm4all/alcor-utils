#! /usr/bin/env bash

ENA0="0xf"
ENA1="0x0"
ENA2="0x0"
ENA3="0x0"
ENA4="0x0"
ENA5="0x0"

#BCRCONF="standard"
BCRCONF="standard.300"
#BCRCONF="high-capacitance.310"
#BCRCONF="max-capacitance.310"
#BCRCONF="low-capacitance.310"
#BCRCONF="minus40c"

RANGE0="1"
RANGE1="1"
RANGE2="1"
RANGE3="1"
RANGE4="3"
RANGE5="3"

DELTA0="5"
DELTA1="5"
DELTA2="5"
DELTA3="5"
DELTA4="25"
DELTA5="25"


DATESTR="$(date +%Y%m%d-%H%M%S)"
DIR=$HOME/DATA/baselineScan/${DATESTR}
ln -sfn $HOME/DATA/baselineScan/${DATESTR} $HOME/DATA/baselineScan/latest
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

### create baseline readout.conf
cat <<EOF > $DIR/readout.baseline.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA0}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE0}
1	 ${ENA1}	 0xb01b         ${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip1.range${RANGE1}
2  	 ${ENA2}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip2.range${RANGE2}
3  	 ${ENA3}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip3.range${RANGE3}
4  	 ${ENA4}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip4.range${RANGE4}
5  	 ${ENA5}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip5.range${RANGE5}
# don't delete this line
EOF
ln -sf $DIR/readout.baseline.conf /au/conf/readout.baseline.conf

### create run readout.conf
cat <<EOF > $DIR/readout.run.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA0}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE0}.delta${DELTA0}
1	 ${ENA1}	 0xb01b         ${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip1.range${RANGE1}.delta${DELTA1}
2  	 ${ENA2}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip2.range${RANGE2}.delta${DELTA2}
3  	 ${ENA3}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip3.range${RANGE3}.delta${DELTA3}
4  	 ${ENA4}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip4.range${RANGE4}.delta${DELTA4}
5  	 ${ENA5}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip5.range${RANGE5}.delta${DELTA5}
# don't delete this line
EOF
ln -sf $DIR/readout.run.conf /au/conf/readout.run.conf

### link main readout.conf
#ln -sf /au/conf/readout.run.conf /au/conf/readout.conf
ln -sf /au/conf/readout.baseline.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

echo " ---"
echo " --- baseline calibration completed "
echo " ---"

