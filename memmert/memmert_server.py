#! /usr/bin/env python3

import socket
import serial

HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
PORT = 65432        # Port to listen on (non-privileged ports are > 1023)

ser = serial.Serial('/dev/MEMMERT', 2400, timeout=1)

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()


timedout = 0
old_setpoint = None
old_temperature = None
old_rh = None

def memmert_in(command):
    command = command + '\r\n'
    ser.write(command.encode())
    data = ser.readline().decode().strip()
    if data == 'OK':
        data = ser.readline().decode().strip()
    return data

def memmert_out(command):
    command = command + '\r\n'
    ser.write(command.encode())
    data = ser.readline().decode().strip()
    return data

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    s.settimeout(1)
    
    while True:
        try:
            conn, addr = s.accept()
            with conn:
                print('Connected by', addr)
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    command = data.decode()
                    print('--- received command:', command)
                    if command.startswith('OUT'):
                        data = memmert_out(command)
                    elif command.startswith('IN'):
                        data = memmert_in(command)
                    else:
                        continue
                    print('--- sending data:', data)
                    conn.sendall(data.encode())
        except Exception as e:
            print(e)
            pass

        temperature = memmert_in('IN_PV_11')
        rh = memmert_in('IN_PV_13')
        setpoint = memmert_in('IN_SP_11')

        if temperature != old_temperature or rh != old_rh or setpoint != old_setpoint or timedout > 100:
            old_temperature = temperature
            old_rh = rh
            thedata_temperature = 'memmert_server,source=memmert,name=temperature value=' + temperature
            thedata_rh = 'memmert_server,source=memmert,name=rh value=' + rh
            thedata = thedata_temperature + '\n' + thedata_rh
            print(thedata)
            session.post(url, data=thedata.encode())
            timedout = 0
        timedout += 1

    
ser.close()
