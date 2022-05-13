#! /usr/bin/env python3

import socket
import serial

HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
PORT = 65432        # Port to listen on (non-privileged ports are > 1023)

ser = serial.Serial('/dev/MEMMERT', 2400, timeout=1)

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
                    if command.startswith('OUT'):
                        data = memmert_out(command)
                    elif command.startswith('IN'):
                        data = memmert_in(command)
                    else:
                        continue
                    print('--- sending data:', data)
                    conn.sendall(data.encode())
    except:
        pass

ser.close()
