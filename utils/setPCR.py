#!/bin/env python

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
    my_parser.add_argument('-c','--chip',action='store',type=functools.partial(int,base=0),help='ALCOR chip # [0-5]')
    my_parser.add_argument('-cha',action='store',type=functools.partial(int,base=0),help='ALCOR channel # [0-31]')
    my_parser.add_argument('-t','--threshold',action='store',type=functools.partial(int,base=0),help='PCR2 field: threshold')
    my_parser.add_argument('-o','--offset',action='store',type=functools.partial(int,base=0),help='PCR2 field: offset')
    my_parser.add_argument('-r','--rangethr',action='store',type=functools.partial(int,base=0),help='PCR2 field: range')
    my_parser.add_argument('-o1',action='store',type=functools.partial(int,base=0),help='PCR3 field: offset1')
    my_parser.add_argument('-op',action='store',type=functools.partial(int,base=0),help='PCR3 field: opmode')
    my_parser.add_argument('-p','--polarity',action='store',type=functools.partial(int,base=0),help='PCR3 field: polarity')
    args = my_parser.parse_args()

    uhal.disableLogging()
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

    if args.chip == None:
        print "Unspecified ALCOR chip # (use -c <value>)"
        exit(0)

    if args.cha == None:
        print "Unspecified ALCOR channel # (use -cha <value>)"
        exit(0)

    chip=args.chip

    alc.verbose=0

#### PCR2
    if (args.threshold != None):
        alc.setPCR2(hw,chip,args.cha,alc.PCR2thr,args.threshold)

    if (args.rangethr != None):
        alc.setPCR2(hw,chip,args.cha,alc.PCR2ran,args.rangethr)

    if (args.offset != None):
        alc.setPCR2(hw,chip,args.cha,alc.PCR2off,args.offset)


### PCR3
    if (args.o1 != None):
        alc.setPCR3(hw,chip,args.cha,alc.PCR3offset1,args.o1)

    if (args.op != None):
        alc.setPCR3(hw,chip,args.cha,alc.PCR3opmode,args.op)

    if (args.polarity != None):
        alc.setPCR3(hw,chip,args.cha,alc.PCR3polarity,args.polarity)

