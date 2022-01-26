#! /usr/bin/env python3

import socket
import os
import vxi11 as vxi

SOCK='/tmp/pulser_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)

dev=vxi.Instrument('10.0.8.11')

def ask(cmd):
    return dev.ask(cmd)

def send(cmd):
    dev.write(cmd)

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.bind(SOCK)
    s.listen()
    
    try:
        while True:
            conn, addr = s.accept()
            with conn:
                print('Connected by', addr)
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    command = data.decode()
                    print('--- received command:', command)
                    if command[-1:] == '?':
                        print('--- ask instrument:', command)
                        data = ask(command)
                        print('--- sending data:', data)
                        conn.sendall(data.encode())
                    else:
                        print(' --- send instrument:', command)
                        send(command)
    except:
        pass
    
dev.close()
