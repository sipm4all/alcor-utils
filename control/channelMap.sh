#!/bin/sh
source ~/.bashrc

### FBK-1
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 0 -m 0x9173F003
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 0 -m 0x0F0FF003
### FBK-2
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 2 -m 0x13737007


### HAMA1
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0x38c3c33c
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0x3cc7c73d
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0x3ecfcf3e
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0x3fefef3f
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0x7fffff7f
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 1 -m 0xffffc3ff

### HAMA2 --- all disabled to be studied
#~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 3 -m 0x38c3c33c
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 3 -m 0x43013CC3
### FBK-2

### BCOM1
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 4 -m 0xc7daeb22
### BCOM2
~/alcor/setParam.py ${ALCOR_ETC}/connection2.xml kc705 -c 5 -m 0x37be6e7f
