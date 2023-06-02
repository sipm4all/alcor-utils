#! /usr/bin/env python3

import socket
import sys
import struct
import numpy as np
import time

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

SOCK='/tmp/arduino_pwm2_control.socket'

while True:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)

        ### temperatures
        s.sendall('temps'.encode())
        size_data = b''
        while len(size_data) < 4:
            chunk = s.recv(4 - len(size_data))
            if not chunk:
                break
            size_data += chunk

            # Unpack the size from the struct
            size = struct.unpack('!I', size_data)[0]

            # Receive the data
            data = b''
            while len(data) < size:
                chunk = s.recv(size - len(data))
                if not chunk:
                    break
                data += chunk

            # Convert the received bytes back to a NumPy array
            arr = np.frombuffer(data, dtype=np.float64)

            # Print the received array
            print("Received array:", arr)

            thedata = '';
            for i in range(0, 12):
                thedata += 'pwm_monitor,source=pwm_monitor_diretta,name=roi' + str(i) + ' value=' + str(arr[i]) + '\n'
            print(thedata)
            session.post(url, data=thedata.encode())

        ### pwms
        s.sendall('pwms'.encode())
        size_data = b''
        while len(size_data) < 4:
            chunk = s.recv(4 - len(size_data))
            if not chunk:
                break
            size_data += chunk

            # Unpack the size from the struct
            size = struct.unpack('!I', size_data)[0]

            # Receive the data
            data = b''
            while len(data) < size:
                chunk = s.recv(size - len(data))
                if not chunk:
                    break
                data += chunk

            # Convert the received bytes back to a NumPy array
            arr = np.frombuffer(data, dtype=np.int64)

            # Print the received array
            print("Received array:", arr)

            thedata = '';
            for i in range(0, 3):
                thedata += 'pwm_monitor,source=pwm_monitor_diretta,name=pwm' + str(i) + ' value=' + str(arr[i]) + '\n'
            print(thedata)
            session.post(url, data=thedata.encode())
        

        ### pidvals
        s.sendall('pidvals'.encode())
        size_data = b''
        while len(size_data) < 4:
            chunk = s.recv(4 - len(size_data))
            if not chunk:
                break
            size_data += chunk

            # Unpack the size from the struct
            size = struct.unpack('!I', size_data)[0]

            # Receive the data
            data = b''
            while len(data) < size:
                chunk = s.recv(size - len(data))
                if not chunk:
                    break
                data += chunk

            # Convert the received bytes back to a NumPy array
            arr = np.frombuffer(data, dtype=np.float64)

            # Print the received array
            print("Received array:", arr)

            thedata = '';
            for i in range(0, 3):
                thedata += 'pwm_monitor,source=pwm_monitor_diretta,name=pidval' + str(i) + ' value=' + str(arr[i]) + '\n'
            print(thedata)
            session.post(url, data=thedata.encode())
        

    time.sleep(1)
            
