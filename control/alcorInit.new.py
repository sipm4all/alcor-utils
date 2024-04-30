#! /usr/bin/env python

import random # For randint
import argparse 
import sys # For sys.argv and sys.exit
import uhal
import ipbus
import alcor as alc
import functools


if __name__ == '__main__':

#  define parser
    my_parser = argparse.ArgumentParser(description='Complete ALCOR configuration for single chip')
    my_parser.add_argument('ConnFile',metavar='IPBUS connection',type=str,help='XML file')
    my_parser.add_argument('CardId',metavar='CARD Id',type=str,help='valid tag: kc705')
    my_parser.add_argument('--eccr',action='store',type=functools.partial(int,base=0),help='force ECCR register value')
    my_parser.add_argument('--bcrfile',action='store',type=str,help='a valid .bcr file')
    my_parser.add_argument('--pcrfile',action='store',type=str,help='a valid .pcr file')
    my_parser.add_argument('-s','--setup',action='store_true',help='Execute setup') 
    my_parser.add_argument('-i','--init',action='store_true',help='Execute setup') 
    my_parser.add_argument('-d','--delay',action='store',type=str,help='alignment delay # [0-31]')
    my_parser.add_argument('-c','--chip',action='store',type=functools.partial(int,base=0),help='ALCOR chip # [0-5]')
    my_parser.add_argument('-p','--pulseType',action='store',type=functools.partial(int,base=0),help='PCR3 pulse field')
    my_parser.add_argument('--phase',action='store',type=functools.partial(int,base=0),help='phase mask 0x0 - 0xF')
    my_parser.add_argument('-l','--lanes',action='store',type=functools.partial(int,base=0),help='lanes mask 0x0 - 0xF')
    my_parser.add_argument('-m','--mask',action='store',type=functools.partial(int,base=0),help='channel mask 0x0 - 0xFFFFFFFF')
    my_parser.add_argument('--oneChannel',action='store',type=functools.partial(int,base=0),help='Single channel setup')
    args = my_parser.parse_args()

    uhal.disableLogging()
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

    if args.chip == None:
        args.chip=0
        print("Unspecified ALCOR chip # (use -c <value>)")
        exit(0)

    uhal.disableLogging()
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

    if args.chip == None:
        args.chip=0
        print("Unspecified ALCOR chip # (use -c <value>)")
        exit(0)

    if args.delay == None:
        args.delay=11

    if args.lanes == None:
        args.lanes=0xF

    if args.phase == None:
        args.phase=0x0
    
    chip=args.chip
    delay=args.delay
    lanes=args.lanes
    phase=args.phase
    
    # grab device's id, or print it to screen
    device_id = hw.id()
    # grab the device's URI
    device_uri = hw.uri()

    alc.verbose=0
    doDefaultSetup = True
    
    # R+SPEED
    if args.oneChannel == None:
        alc.oneChannel = False
    else:
        alc.oneChannel = True
        alc.theChannel = args.oneChannel
        doDefaultSetup = False
    
    print("-------- ALCOR # ",chip," Complete Setup")
    print("KC705 mode set to config")
    data=0x0
    ipstat=ipbus.write(hw,"regfile.mode",data)
    print("Resetting fifos for ALCOR # ",chip)

    alc.resetFifo(hw,chip)
    
    # 
    if args.init == True:
        print("Alcor reset and lanes alignment")
        ### R+fix
#        retcode = alc.init(hw,chip)
#        while retcode != 0:
#            retcode = alc.init(hw,chip)
        retcode=alc.init2(hw,chip,delay,lanes,phase)
            
    # load setup
    if args.setup == True:
        ### R+SPEED
        if doDefaultSetup:
            print("Setting Alcor registers to default")
            alc.setup(hw,chip,args.pulseType,0)
#        alc.setup(hw,chip,args.pulseType,args.mask)
#        alc.setupECCR(hw,chip,alc.ECCR_default|alc.ECCR_RAWMODE)
        if args.eccr != None:
            print("Setting ECCR to: ",hex(args.eccr))
            alc.setupECCR(hw,chip,args.eccr)

    alc.setChannelMask(hw,chip,0)

    if args.bcrfile != None:
        print("Executing custom BCR setup")
        alc.loadBCRSetup(hw,chip,args.bcrfile)

    if args.pcrfile != None:
        print("Executing custom PCR setup (channel ON/OFF driven by PCR file & mask)")
        alc.loadPCRSetup(hw,chip,args.pcrfile,args.mask)
    else:
        print("No custom PCR setup (channel ON/OFF driven by mask: ",hex(args.mask),")")
        alc.setChannelMask(hw,chip,args.mask)


    alc.sendTestPulse(hw,chip)

    print("------ End of configuration ")
### TMP
## protezione per HAMA1 cosi' carichiamo maschera a mano
#    if (args.chip == 1):
#        args.mask=0x3cc3c33c
#        alc.setChannelMask(hw,chip,args.mask)
