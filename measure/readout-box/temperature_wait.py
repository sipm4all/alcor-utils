#! /usr/bin/env python3

import socket
import argparse
import time
import math
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--ml', type=int, choices=[0, 1, 2, 3], required=True, help="masterlogic number")
parser.add_argument('--tset', type=float, required=True, help="desired temperature")
parser.add_argument('--delta', type=float, default=0.1, help="maximum temperature difference")
parser.add_argument('--time', type=int, default=600, help="minimum time in seconds not violating maximum difference")
parser.add_argument('--sleep', type=int, default=60, help="sleep between checks")
args = vars(parser.parse_args())

start = time.time()

SOCK='/tmp/masterlogic_server.ML' + str(args['ml']) + '.socket'
tset=args['tset']

while True:
    
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCK)
            s.sendall('L'.encode())
            data = s.recv(1024).decode()
            tcur=float(data.split()[2])
            
            ### check if close to set value, if not reset timer
            if math.fabs(tcur - tset) > args['delta']:
                start = time.time()
                
            elapsed = time.time() - start
            print(' target_temperature =', tset, ' current_temperature =', tcur, ' delta_temperature =', tcur - tset, ' elapsed_time = ', int(elapsed))
            sys.stdout.flush()
                
            ### check if timer is sufficiently large, break loop in case
            if elapsed >= args['time']:
                break
        
    except Exception as e:
        start = time.time()
        print(e)        

    time.sleep(args['sleep'])        
        
exit(0)
