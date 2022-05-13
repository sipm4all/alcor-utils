#!/usr/bin/env python3

import socket
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--axis', type=int, choices=[1, 2], required=True, help="axis number")
parser.add_argument('--cmd', type=str, required=True, help="masterlogic command")
args = vars(parser.parse_args())

SOCK='/tmp/standa_server.axis' + str(args['axis']) + '.socket'

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCK)
    s.sendall(args['cmd'].encode())
    data = s.recv(1024).decode()
print(data)
