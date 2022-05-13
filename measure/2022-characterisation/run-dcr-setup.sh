#! /usr/bin/env bash

### switch off HV
/au/tti/hv.off

### prepare to run bolognaScan
cat <<EOF > readout.maxthreshold.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 0x0 		 0xb01b 	minus40c	maxthreshold
1	 0x0 		 0xb01b 	minus40c	maxthreshold
2  	 0xf 		 0xb01b 	minus40c	maxthreshold
3  	 0xf		 0xb01b 	minus40c	maxthreshold
4  	 0x0 		 0xb01b 	plus20c		maxthreshold
5  	 0x0 		 0xb01b 	plus20c		maxthreshold
# don't delete this line
EOF
ln -sf $PWD/readout.maxthreshold.conf /au/conf/readout.conf

### bolognaScan
/au/readout/scripts/bolognaScan.sh $PWD/bolognaScan | tee bolognaScan.log

### link PCR files 
ln -sf $PWD/bolognaScan /au/conf/pcr/dcr-setup/.

cat <<EOF > readout.range1.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 0x0 		 0xb01b 	minus40c	maxthreshold
1	 0x0 		 0xb01b 	minus40c	maxthreshold
2  	 0xf 		 0xb01b 	minus40c	dcr-setup/bolognaScan/PCR/chip2.range1
3  	 0xf		 0xb01b 	minus40c	dcr-setup/bolognaScan/PCR/chip3.range1
4  	 0x0 		 0xb01b 	plus20c		maxthreshold
5  	 0x0 		 0xb01b 	plus20c		maxthreshold
# don't delete this line
EOF
ln -sf $PWD/readout.range1.conf /au/conf/readout.conf

### switch on HV with DAC = zero
/au/masterlogic/zero 2
/au/masterlogic/zero 3
/au/masterlogic/wait
/au/tti/hv.on

### bolognaScan
/au/readout/scripts/bolognaScan.sh $PWD/bolognaScan final true | tee bolognaScan.log
/au/readout/scripts/draw_allchannel.sh $PWD/bolognaScan final
