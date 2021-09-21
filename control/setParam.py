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
    my_parser.add_argument('--eccr',action='store',type=functools.partial(int,base=0),help='force ECCR register value')
    my_parser.add_argument('-c','--chip',action='store',type=functools.partial(int,base=0),help='ALCOR chip # [0-5]')
    my_parser.add_argument('--on',action='store',type=functools.partial(int,base=0),help='turn on a channel [0-31]')
    my_parser.add_argument('--off',action='store',type=functools.partial(int,base=0),help='turn off a channel [0-31]')
    my_parser.add_argument('-t','--threshold',action='store',type=functools.partial(int,base=0),help='PCR3 field: threshold')
    my_parser.add_argument('-m','--mask',action='store',type=functools.partial(int,base=0),help='channel mask 0x0 - 0xFFFFFFFF')
    args = my_parser.parse_args()

    uhal.disableLogging()
    connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
    hw = connectionMgr.getDevice(args.CardId)

    if args.chip == None:
        print "Unspecified ALCOR chip # (use -c <value>)"
        exit(0)

    if args.mask == None:
        print "Unspecified channel mask # (use -m 0x<value>)"
        exit(0)
        

    chip=args.chip

    alc.verbose=0

    if (args.mask != None):
        alc.setChannelMask(hw,chip,args.mask)

    if (args.threshold != None):
        alc.thresholdOnly(hw,chip,args.threshold,args.mask)
