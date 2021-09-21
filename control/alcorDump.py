#!/bin/env python

import argparse 
import sys # For sys.argv and sys.exit
import uhal
import ipbus
import alcor as alc
import functools


bcrr = []
eccr = []
pcrr = []

def readALREG(hw,chip,ch,regType):
    global bcrr
    global eccr
    global pcr
    d=0
    for ad in range(alc.regNr[regType]):
        if (regType == alc.PCR):
            reg = ((ch&0x3C)<<3) | ((ch&0x3)<<2) | ad
        else:
            ch=0
            reg = ad
        data=alc.programPtrReg(hw,chip,regType,reg,d,alc.RDREG)
#        print "READ ",hex(data),ch,hex(reg)
        if (regType == alc.BCR): 
            bcrr.append(str(hex(data&0xFFFF)))
        elif (regType == alc.ECCR): 
            eccr.append(str(hex(data&0xFFFF)))
        elif (regType == alc.PCR): 
            pcrr.append(str(hex(data&0xFFFF)))


if __name__ == '__main__':

#  define parser
    my_parser = argparse.ArgumentParser(description='Dump ALCOR Registers configuration')
    my_parser.add_argument('ConnFile',metavar='IPBUS connection',type=str,help='XML file')
    my_parser.add_argument('CardId',metavar='CARD Id',type=str,help='valid tag: kc705')
    my_parser.add_argument('-c','--chip',action='store',type=functools.partial(int,base=0),help='ALCOR chip # [0-5]')
    args = my_parser.parse_args()

    uhal.disableLogging()
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

    if args.chip == None:
        args.chip=0
        print "Unspecified ALCOR chip # (use -c <value>), forcing it to 0"

    chip=args.chip

    # grab device's id, or print it to screen
    device_id = hw.id()
    # grab the device's URI
    device_uri = hw.uri()

    readALREG(hw,chip,0,alc.BCR)
    readALREG(hw,chip,0,alc.ECCR)
    for ch in range(alc.channels):
        readALREG(hw,chip,ch,alc.PCR)

    print "BCR ",
    for i in range(alc.BCRregs):
        print bcrr[i],
    print " "
    print "ECCR",
    for i in range(alc.ECCRregs):
        print eccr[i],
    print " "
    print "PCR ",
    for ch in range(alc.channels):
        for i in range(alc.PCRregs):
            ii=i+ch*alc.PCRregs
            print pcrr[ii],
    print " "
