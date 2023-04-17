#! /usr/bin/env python3
#
import socket
import subprocess
import sys
import time
#
HOST = '10.0.8.101'
PORT = 3482
#
# Check command is there
if len( sys.argv ) < 2:
    print("[ERROR] Must specify a command")
    sys.exit(0)
#
command = sys.argv[1]
print("[INFO] Sending command: ",command)
#
with socket.socket( socket.AF_INET, socket.SOCK_STREAM ) as stream:
    stream.connect((HOST,PORT))
    stream.sendall(command.encode())
    data = stream.recv(1024).decode()
    print(data)
    
