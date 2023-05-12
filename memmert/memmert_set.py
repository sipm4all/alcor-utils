#! /usr/bin/env python3

import socket
import argparse

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

parser = argparse.ArgumentParser()
parser.add_argument('--mode', choices=['0', '1'], help='mode')
parser.add_argument('--temp', help="temperature (C)")
parser.add_argument('--rh', help="relative humidity (%%)")
parser.add_argument('--fan', choices=['{:X}'.format(x) for x in range(0,11)], help="fan speed")
args = vars(parser.parse_args())

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(10)
        s.connect((HOST, PORT))

        if args['temp'] is not None:
            temperature = "{0:.1f}".format(float(args['temp']))
            print(' --- setting temperature:', temperature)
            command = 'OUT_SP_11_' + temperature
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- response:', data)
            command = 'IN_SP_11'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- temperature set value:', data)
            
        if args['mode'] is not None:
            mode = args['mode']
            print(' --- setting mode:', mode)
            command = 'OUT_MODE_10_' + mode
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- response:', data)
            command = 'IN_MODE_10'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- mode set value:', data)
            
        if args['rh'] is not None:
            humidity = args['rh']
            print(' --- setting humidity:', humidity)
            humidity = '{}'.format(int(10 * float(args['rh'])))
            command = 'OUT_SP_13_' + humidity
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- response:', data)
            command = 'IN_SP_13'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- humidity set value:', data)
                
        if args['fan'] is not None:
            fan = args['fan']
            print(' --- setting fan:', fan)
            command = 'OUT_SP_15_' + fan
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- response:', data)
            command = 'IN_SP_15'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- fan set value:', data)

except Exception as e:
    print(e)        
    exit(1)
        
exit(0)

