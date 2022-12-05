#!/usr/bin/env python3

import socket
import argparse
import time

parser = argparse.ArgumentParser()
parser.add_argument('--peltier', type=int, choices=[3, 4], required=True, help="peltier number")
parser.add_argument('--cmd', type=str, required=True, help="peltier command")
args = vars(parser.parse_args())

SOCK='/tmp/peltier-barion-server.PELTIER' + str(args['peltier']) + '.socket'

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCK)
    cmds = args['cmd'].split()
    for cmd in cmds:
        s.sendall(cmd.encode())
        data = s.recv(1024).decode()
        print(data)
        time.sleep(1)
