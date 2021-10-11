#!/bin/env python

import argparse 
import uhal
import alcor as alc
import ipbus
import functools

import signal
import sys
import sysv_ipc as ipc
import time

def sigint_handler(signal, frame):
    global alcorCtrl
    print 'Interrupted, detaching from shared memory'
    alcorCtrl.write("END\0",0)
#    time.sleep(1)
#    alcorCtrl.write("QUIT\0",0)
    alcorCtrl.detach()
    sys.exit(0)

def waitAck():
    global alcorCtrl
    while True:
        ack=alcorCtrl.read(1,0)
        if (ack == "A"):
            break


def attachAlcorCtrl():
    path = "/tmp/alcorReadoutController.shmkey"
    key = ipc.ftok(path, 2333,silence_warning=True)
    shm = ipc.SharedMemory(key, 0, 0)
    shm.attach()  
    return shm


if __name__ == '__main__':

#  define parser
    my_parser = argparse.ArgumentParser(description='Start ALCOR threshold scan')
    my_parser.add_argument('ConnFile',metavar='IPBUS connection',type=str,help='XML file')
    my_parser.add_argument('CardId',metavar='CARD Id',type=str,help='valid tag: kc705')
    my_parser.add_argument('-s','--setup',action='store_true',help='Execute setup') 
    my_parser.add_argument('-i','--init',action='store_true',help='Execute init (align)') 
    my_parser.add_argument('--nowait',action='store_true',help='nowait DAQ') 
    my_parser.add_argument('-m','--mask',action='store',type=functools.partial(int,base=0),help='Channel mask')
    my_parser.add_argument('-p','--pulseType',action='store',type=functools.partial(int,base=0),help='Pulse Type [0-6]')
    my_parser.add_argument('-n','--numberPulses',action='store',type=functools.partial(int,base=0),help='# pulses')
    my_parser.add_argument('-c','--chip',action='store',type=functools.partial(int,base=0),help='ALCOR chip # [0-3]')
    my_parser.add_argument('--thrmin',action='store',type=functools.partial(int,base=0),help='minimum threshold')
    my_parser.add_argument('--eccr',action='store',type=functools.partial(int,base=0),help='force ECCR register value')
    my_parser.add_argument('--bcr0',action='store',type=functools.partial(int,base=0),help='force BCR 0-2-4-6 register value')
    my_parser.add_argument('--bcr1',action='store',type=functools.partial(int,base=0),help='force BCR 1-3-5-7 register value')
    my_parser.add_argument('--pcrfile',action='store',type=str,help='a valid .pcr file')
    my_parser.add_argument('--bcrfile',action='store',type=str,help='a valid .bcr file')
    my_parser.add_argument('--msleep',action='store',type=str,help='a valid .pcr file')


    args = my_parser.parse_args()

#    alcorCtrl=attachAlcorCtrl();
    signal.signal(signal.SIGINT, sigint_handler)
    param="RESET\0"
#    alcorCtrl.write("RESET\0",0)
    
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

##
    if args.mask == None:
        args.mask=0x1
        print "Unspecified channel mask (use -m 0x<value>), forcing it to ",hex(args.mask)
    if args.pulseType == None:
        args.pulseType=alc.PIX_LET_TP_TDC
        print "Unspecified pulse type (use -t <value>), forcing it to LET_TP_TOC"
    if args.chip == None:
        args.chip=0
        print "Unspecified ALCOR chip # (use -c <value>), forcing it to 0"
    if args.numberPulses == None:
        args.numberPulses=0
    if args.msleep == None:
        waitSec=1
    else:
        waitSec=int(args.msleep)/1000.
    if args.thrmin == None:
        args.thrmin=0
    chip=args.chip
##

    # grab device's id, or print it to screen
    device_id = hw.id()
    # grab the device's URI
    device_uri = hw.uri()

    data=0x0
    ipstat=ipbus.write(hw,"regfile.mode",data)
    alc.resetFifo(hw,chip)

    # load setup
    if args.init == True:
        alc.init(hw,chip)

    if args.setup == True:
        alc.setup(hw,chip,args.pulseType,args.mask)
        if args.eccr != None:
            alc.setupECCR(hw,chip,args.eccr)
        if args.bcr0 != None:
            alc.setupBCR(hw,chip,0,args.bcr0)
        if args.bcr1 != None:
            alc.setupBCR(hw,chip,1,args.bcr1)

    alc.setChannelMask(hw,chip,0)
    if args.bcrfile != None:
        print "Executing custom BCR setup"
        alc.loadBCRSetup(hw,chip,args.bcrfile)

    if args.pcrfile != None:
        print "Executing custom PCR setup"
        alc.loadPCRSetup(hw,chip,args.pcrfile,args.mask)

    alc.setChannelMask(hw,chip,args.mask)
        


# specific for ALCORtest to avoid oscillations. Baseline set to 8 instead of 12
# alc.setBias(hw,chip,8,25,1)

    icnt=0
    alc.verbose=0
    data=0x1
    r=alc.fifoRegList[chip]
    p=alc.pulserRegList[chip]

#    for offset in range(alc.ThrOffsetMax+1):
#        for rangeThr in range(alc.ThrRangeMax,-1,-1):
    offset=3     ## for Broadcom
    rangeThr=0   ## for Broadcom
    for thrValue in range(63,args.thrmin-1,-1):    
#        print "Setting OFF/RANGE/THR",offset,rangeThr,thrValue,
        data=0x0
        ipstat=ipbus.write(hw,"regfile.mode",data)
        alc.resetFifo(hw,chip)

        alc.threshold(hw,chip,thrValue,rangeThr,offset,args.mask)  # other channels will be switched off
        icnt += 1
        param="BEGIN O"+str(offset)+"R"+str(rangeThr)+"THR"+str(thrValue).zfill(2)+"\0"
#        alcorCtrl.write(param,0)
        if (args.nowait != True):
            waitAck()
        for x in range(args.numberPulses): 
            ipstat=ipbus.write(hw,"pulser."+p,data)

        data=0x1
        ipstat=ipbus.write(hw,"regfile.mode",data)
        time.sleep(0.001)
        data=0x3
        ipstat=ipbus.write(hw,"regfile.mode",data)
        time.sleep(waitSec)

        print "Thr ",thrValue,
        for i in range(alc.lanes):
            r=alc.fifoRegList[chip]+"_lane{}.fifo_occupancy".format(i)
            ipstat=ipbus.read(hw,r)
            occ=ipstat&0xFFFF
            print occ,
        print " "
#            if (occ>100):
#                print "Baseline ",chip,hex(args.mask),thrValue
#                exit()
#        if (occ>0):
#            occ=10
#            for w in range(occ):
#                ipstat=ipbus.read(hw,r+".fifo_data")
#                print "[Word# ",w,
#                alc.data(ipstat)
#        alcorCtrl.write("END\0",0)
        if (args.nowait != True): 
            waitAck()
#    print "Baseline not found ",chip,hex(args.mask)
#    print "Scanned ",icnt,"values"
#    alcorCtrl.write("QUIT\0",0)
#    alcorCtrl.detach()

