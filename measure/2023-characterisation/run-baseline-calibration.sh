#! /usr/bin/env bash

BCRCONF="standard"
ENA=("0xf" "0x0" "0x0" "0x0" "0x0" "0x0")
RANGE=("1" "1" "1" "1" "3" "3")
DELTA=("5" "5" "5" "5" "25" "25")

### BCR configuration from external parameter
if [ -n "$1" ]; then
    BCRCONF=$1
    if [ ! -f "/au/conf/bcr/$BCRCONF.bcr" ]; then
	echo " --- unknown BCR configuration: $BCRCONF " 
	exit 1
    fi
fi

### active chips from external parameter
if [ -n "$2" ]; then
    for CHIP in ${ENA[@]}; do
	ENA[$CHIP]="0x0"
    done
    ACTIVE_CHIPS=$2
    for CHIP in $2; do
	ENA[$CHIP]="0xf"
    done
fi

DATESTR="$(date +%Y%m%d-%H%M%S)"
DIR=$HOME/DATA/baselineScan/${DATESTR}
ln -sfn $HOME/DATA/baselineScan/${DATESTR} $HOME/DATA/baselineScan/latest
mkdir -p $DIR

echo " ---"
echo " --- starting baseline calibration: $DIR "
echo " --- running with BCR configuration: $BCRCONF "
echo " --- enable configuration: ${ENA[@]} "
echo " ---"

### HV must be ON with all DACs at zero
for I in {0..3}; do
    /au/masterlogic/zero $I &> /dev/null &
done
wait
sleep 3
/au/tti/hv.on

### prepare to run bolognaScan
cat <<EOF > $DIR/readout.maxthreshold.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA[0]}	 0xb01b         ${BCRCONF}	maxthreshold
1	 ${ENA[1]}	 0xb01b 	${BCRCONF}	maxthreshold
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	maxthreshold
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	maxthreshold
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	maxthreshold
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	maxthreshold
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
0 	 ${ENA[0]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE[0]}
1	 ${ENA[1]}	 0xb01b         ${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip1.range${RANGE[1]}
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip2.range${RANGE[2]}
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip3.range${RANGE[3]}
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip4.range${RANGE[4]}
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip5.range${RANGE[5]}
# don't delete this line
EOF
ln -sf $DIR/readout.baseline.conf /au/conf/readout.baseline.conf

### create run readout.conf
cat <<EOF > $DIR/readout.run.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA[0]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE[0]}.delta${DELTA[0]}
1	 ${ENA[1]}	 0xb01b         ${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip1.range${RANGE[1]}.delta${DELTA[1]}
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip2.range${RANGE[2]}.delta${DELTA[2]}
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip3.range${RANGE[3]}.delta${DELTA[3]}
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip4.range${RANGE[4]}.delta${DELTA[4]}
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip5.range${RANGE[5]}.delta${DELTA[5]}
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

