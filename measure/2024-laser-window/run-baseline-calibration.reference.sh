#! /usr/bin/env bash

BCRCONF="standard"
RANGE=("1" "1" "1" "1" "3" "3")

### chech if an external range is defined 
if [ -n "$AU_BOLOGNASCAN_RANGE" ]; then
    echo " --- forcing external range: $AU_BOLOGNASCAN_RANGE "
    RANGE[0]=$AU_BOLOGNASCAN_RANGE
    RANGE[1]=$AU_BOLOGNASCAN_RANGE
    RANGE[2]=$AU_BOLOGNASCAN_RANGE
    RANGE[3]=$AU_BOLOGNASCAN_RANGE
fi

### BCR configuration from external parameter
if [ -n "$1" ]; then
    BCRCONF=$1
    if [ ! -f "/au/conf/bcr/$BCRCONF.bcr" ]; then
	echo " --- unknown BCR configuration: $BCRCONF " 
	exit 1
    fi
fi

DATESTR="$(date +%Y%m%d-%H%M%S)"
DIR=$HOME/DATA/baselineScan/${DATESTR}
ln -sfn $HOME/DATA/baselineScan/${DATESTR} $HOME/DATA/baselineScan/latest
mkdir -p $DIR

echo " ---"
echo " --- starting baseline calibration: $DIR "
echo " --- running with BCR configuration: $BCRCONF "
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
0 	 0xf		 0xb01b         ${BCRCONF}	maxthreshold
1	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
2  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
3  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
4  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
5  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
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
0 	 0xf		 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE[0]}
1	 0x0		 0xb01b         ${BCRCONF}	testpulse
2  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
3  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
4  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
5  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.baseline.conf /au/conf/readout.baseline.conf

### link main readout.conf
ln -sf /au/conf/readout.baseline.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $DIR final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

### create run readout.conf
cat <<EOF > $DIR/readout.run.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 0xf		 0xb01b 	${BCRCONF}	dcr-setup/${DATESTR}/PCR/chip0.range${RANGE[0]}.current
1	 0x1		 0xb01b         ${BCRCONF}	testpulse
2  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
3  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
4  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
5  	 0x0		 0xb01b 	${BCRCONF}	maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.run.conf /au/conf/readout.run.conf

### link main readout.conf
ln -sf /au/conf/readout.run.conf /au/conf/readout.conf

echo " ---"
echo " --- baseline calibration completed "
echo " ---"

