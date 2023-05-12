#! /usr/bin/env python

import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('10.0.8.13', 5030)

sock.connect(server_address)
sock.close()
