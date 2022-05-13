#! /usr/bin/env python3

import socket
import argparse

### arguments
parser = argparse.ArgumentParser(description='Keithley ivscan program', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--address', type=str, required=True, help='IP address')
args = parser.parse_args()

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = (args.address, 5025)

def connect():
    sock.connect(server_address)

def close():
    sock.close()

def send(command):
    command += '\n'
    sock.send(command.encode())

def recv():
    data = sock.recv(4096)
    data = data.decode()
    while data[-1] != '\n':
        data += sock.recv(4096)
    return data.strip()

def initialize():
    send('ABORT')
    send('*RST')
    send('STAT:CLE')
    send('SYST:CLE')
    send('*IDN?')
    data = recv()
    print('--- instrument initialised: %s ' % data)

connect()
initialize()
close()
