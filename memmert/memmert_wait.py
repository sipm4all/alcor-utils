#! /usr/bin/env python3

import socket
import argparse
import time
import math
import sys

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

parser = argparse.ArgumentParser()
parser.add_argument('--delta', type=float, default=0.5, help="maximum temperature difference")
parser.add_argument('--time', type=int, default=600, help="minimum time in seconds not violating maximum difference")
parser.add_argument('--sleep', type=int, default=60, help="sleep between checks")
args = vars(parser.parse_args())

start = time.time()

while True:

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((HOST, PORT))
            s.sendall('IN_SP_11'.encode())
            tset = float(s.recv(1024).decode())
            s.sendall('IN_PV_11'.encode())
            tcur = float(s.recv(1024).decode())
            
            ### check if close to set value, if not reset timer
            if math.fabs(tcur - tset) > args['delta']:
                start = time.time()
                
            elapsed = time.time() - start
            print(' target_temperature =', tset, ' current_temperature =', tcur, ' delta_temperature =', tcur - tset, ' elapsed_time = ', int(elapsed))
            sys.stdout.flush()
                
            ### check if timer is sufficiently large, break loop in case
            if time.time() - start >= args['time']:
                break
                                
    except Exception as e:
        start = time.time()
        print(e)        

    time.sleep(args['sleep'])        
        
exit(0)
