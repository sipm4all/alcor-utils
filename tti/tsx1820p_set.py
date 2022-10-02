#! /usr/bin/env python3

import socket
import argparse

SOCK='/tmp/tsx1820p_server.socket'

parser = argparse.ArgumentParser()
parser.add_argument('--vset', help="set voltage (V)")
parser.add_argument('--iset', help="set current (A)")
parser.add_argument('--status', choices=['0', '1'], help="channel status (on/off)")
args = vars(parser.parse_args())

queries = { 'vset' : 'V1?' , 'vout' : 'V1O?' , 'iset' : 'I1?' , 'iout' : 'I1O?' , 'status' : 'OP1?' }

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)

        if args['vset']:
            command = 'V1 ' + args['vset']
            s.sendall(command.encode())
            data = s.recv(1024).decode()
        
        if args['iset']:
            command = 'I1 ' + args['iset']
            s.sendall(command.encode())
            data = s.recv(1024).decode()
        
        if args['status']:
            command = 'OP1 ' + args['status']
            s.sendall(command.encode())
            data = s.recv(1024).decode()

        for query in queries:
            s.sendall(queries[query].encode())
            data = s.recv(1024).decode()
            print(' --- %s: %s' % (query, data))
            
except Exception as e:
    print(e)
    exit(1)

exit(0)



