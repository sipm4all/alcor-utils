#! /usr/bin/env python3

import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('10.0.8.11', 1008)

sock.connect(server_address)
print(' --- connected')

command = '*IDN? \n'
sock.send(command.encode())
print(' --- command send')
data = sock.recv(4096)
print(' --- data received')
print(data)

sock.close()
