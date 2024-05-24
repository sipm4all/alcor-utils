#
#
#  SPI routines 
#  (these could be moved to alcor.py in future, given we have now a dependency through chip-register mapping)
#


import ipbus
import alcor as alc

CTRL_BIT_NB    	= 14
CTRL_ASS       	= 13
CTRL_IE	       	= 12 
CTRL_LSB	= 11 
CTRL_TX_NEGEDGE = 10 
CTRL_RX_NEGEDGE = 9 
CTRL_GO 	= 8 
CTRL_RES_1 	= 7
CTRL_CHAR_LEN   = 6 
COMMAND         = 20
POINTER         = 12
RPTR            = 8
WPTR            = 0
RDAT            = 9
WDAT            = 1
RSREG           = 8

spiDividerInit={0:0,1:0,2:0,3:0}

def PTR(ptrId):
    """Encode a valid PCR identifier"""
    return (ptrId<<POINTER)

def CMD(data):
    """Encode a valid SPI command in right bit position"""
    return (data<<COMMAND)


def bS(ibit):
    """ Return an integer with bit ibit set"""
    return (1<<ibit)


def execCmd(hw,chip,command,tdata):
    """Execute SPI command writing tdata via SPI interface"""

    r=alc.spiRegList[chip]
#    ipstat=ipbus.post(hw,r+".divider",0xF)
    ipstat=ipbus.post(hw,r+".divider",0x1F) ### good for 4m cables
    ipstat=ipbus.post(hw,r+".ss",0x1)

    data=bS(CTRL_ASS)|bS(CTRL_RX_NEGEDGE)|0x18
    ipstat=ipbus.post(hw,r+".ctrl",data)

    data=CMD(command)|(tdata&0xFFFF)
#    print "Writing ",hex(tdata)+" with SPI command "+spiCmdList[command]

    ipstat=ipbus.post(hw,r+".tx0_rx0",data)  # when we transmit a command, we also pass data in lower 16 bits

    data=bS(CTRL_ASS)|bS(CTRL_RX_NEGEDGE)|bS(CTRL_GO)|0x18
    ipstat=ipbus.post(hw,r+".ctrl",data)

    data=bS(CTRL_ASS)|bS(CTRL_RX_NEGEDGE)|0x18
    ipstat=ipbus.write(hw,r+".ctrl",data)

    ipstat=ipbus.read(hw,r+".tx0_rx0")
    return ipstat
