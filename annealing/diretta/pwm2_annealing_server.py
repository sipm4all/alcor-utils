#!/usr/bin/env python3

from mlsocket import MLSocket
from simple_pid import PID
import numpy as np
import socket
import os
import socket
import struct

running = True
coordinates_file = '/au/annealing/diretta/centers.npy'
sipm = 12
rows = 3

### acquire an image from FLIR
def acquire_image():
	HOST = '127.0.0.1'
	PORT = 40001
	with MLSocket() as s:
	        s.connect((HOST, PORT)) # Connect to the port and host
	        s.send('acquire'.encode())
	        data = s.recv(1024)
	return data

### retrieve temperatures 
def get_temperatures(coordinates):
        temperatures = np.empty(sipm)
        data = acquire_image()
        for i in range(0, sipm):
                x=int(coordinates[1, i])
                y=int(coordinates[0, i])
                temperatures[i] = data[x,y]
        return temperatures

### compute row temperatures
def get_row_temperatures(temperatures):

        channels_A = [11, 2, 8, 7]
        channels_B = [9, 10, 3, 0]
        channels_C = [1, 4, 5, 6]

        row_temperatures = np.empty(rows)
        row_temperatures[0] = (temperatures[1] + temperatures[4] + temperatures[5] + temperatures[6]) / 4.;
        row_temperatures[1] = (temperatures[11] + temperatures[2] + temperatures[8] + temperatures[7]) / 4.;
        row_temperatures[2] = (temperatures[9] + temperatures[10] + temperatures[3] + temperatures[0]) / 4.;

        row_temperatures[0] = max([temperatures[1], temperatures[4], temperatures[5], temperatures[6]])
        row_temperatures[1] = max([temperatures[11], temperatures[2], temperatures[8], temperatures[7]])
        row_temperatures[2] = max([temperatures[9], temperatures[10], temperatures[3], temperatures[0]])
        
        return row_temperatures;

        ### possible protection
        
        for i in channels_A:
                avetemp = 0
                navetemp = 0
                if abs(temperatures[i] - row_temperatures[0]) < 10.:
                        avetemp = avetemp + temperatures[i]
                        navetemp = navetemp + 1
        if navetemp == 0:
                row_temperatures[0] = 200.
        else:
                row_temperatures[0] = avetemp / navetemp

        for i in channels_B:
                avetemp = 0
                navetemp = 0
                if abs(temperatures[i] - row_temperatures[1]) < 10.:
                        avetemp = avetemp + temperatures[i]
                        navetemp = navetemp + 1
        if navetemp == 0:
                row_temperatures[1] = 200.
        else:
                row_temperatures[1] = avetemp / navetemp

        for i in channels_C:
                avetemp = 0
                navetemp = 0
                if abs(temperatures[i] - row_temperatures[2]) < 10.:
                        avetemp = avetemp + temperatures[i]
                        navetemp = navetemp + 1
        if navetemp == 0:
                row_temperatures[2] = 200.
        else:
                row_temperatures[2] = avetemp / navetemp

        return row_temperatures;
        
### calibrated PWM
def calibrated_pwm(channel, value):
#        channels_A = [13]
#        channels_B = [14]
#        channels_C = [12]
        channels_A = [1]
        channels_B = [2]
        channels_C = [0]

        params_A = [-96.5213, 4.8253, -0.0472882, 0.000174364]
        params_B = [-70.0336, 3.28262, -0.0269523, 0.000126457]
        params_C = [-105.347, 4.96875, -0.0467982, 0.000182697]

        print(channel)
        
        params = []
        if channel in channels_A:
                params = params_A
        elif channel in channels_B:
                params = params_B
        elif channel in channels_C:
                params = params_C
        else:
                return 0
                
        pwm = params[0] + params[1] * value + params[2] * value ** 2 + params[3] * value ** 3
        if pwm < 0:
                pwm = 0
        return pwm
                
### send PWM command
def send_pwms(pwms):
        SOCK='/tmp/arduino_pwm2_server.socket'
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCK)
                command = 'PWM 0,0,0,0,0,0,0,0,0,0,0,0,' + ','.join(map(str, pwms))
                s.sendall(command.encode())            

### reset PWMs
pwms = np.zeros(rows, dtype=int)
pidvals = np.zeros(rows, dtype=float)
send_pwms(pwms)

### load coordinates
coordinates = np.load(coordinates_file)

### get current temperatures
temperatures = get_temperatures(coordinates)
row_temperatures = get_row_temperatures(temperatures)

### initialise pwm PIDs
pids = [None] * rows
current_setpoint = np.copy(row_temperatures)
target_setpoint = np.copy(row_temperatures)
for i in range(0, rows):
        pids[i] = PID(0.1, 0.05, 0.1, setpoint = current_setpoint[i])
        pids[i].sample_time = 2.
        pids[i].output_limits = (25., 250.)
        pids[i].auto_mode = True

### open socket and listen
SOCK='/tmp/arduino_pwm2_control.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        
        s.bind(SOCK)
        s.listen()
        s.settimeout(2)

        ### commands
        while running:
                try:
                        conn, addr = s.accept()
                        with conn:
                                print('Connected by', addr)
                                while True:
                                        data = conn.recv(1024)
                                        if not data:
                                                break
                                        command = data.decode()
                                        print(' --- received command:', command)
                                        command = command.split()
                                        if command[0] == 'on':
                                                pass
                                        elif command[0] == 'temps':
                                                temperatures_data = temperatures.tobytes()
                                                size = struct.pack('!I', len(temperatures_data))
                                                conn.sendall(size)
                                                conn.sendall(temperatures_data)
                                        elif command[0] == 'pwms':
                                                pwms_data = pwms.tobytes()
                                                size = struct.pack('!I', len(pwms_data))
                                                conn.sendall(size)
                                                conn.sendall(pwms_data)
                                        elif command[0] == 'pidvals':
                                                pidvals_data = pidvals.tobytes()
                                                size = struct.pack('!I', len(pidvals_data))
                                                conn.sendall(size)
                                                conn.sendall(pidvals_data)
                                        elif command[0] == 'quit':
                                                running = False;
                                        elif command[0] == 'off':
                                                pass
                                        elif command[0] == 'set':
                                                if len(command) == 2:
                                                        for i in range(0, rows):
                                                                target_setpoint[i] = float(command[1])
                                                                current_setpoint[i] = target_setpoint[i]
                                                        volt_target_setpoint = float(command[1])
                                                        volt_current_setpoint = volt_target_setpoint
                                                        print(' --- set point for all:', current_setpoint)
                                                if len(command) == 3:
                                                        channel = int(command[2])
                                                        print(' --- set point for channel', channel, ':', current_setpoint)
                                        elif command[0] == 'goto':
                                                if len(command) == 2:
                                                        print(' --- goto point for all:', command[1])
                                                        for i in range(0, rows):
                                                                target_setpoint[i] = float(command[1])
                                                if len(command) == 3:
                                                        channel = int(command[2])
                                                        print(' --- goto point for channel', channel, ':', command[1])
                                                        target_setpoint[channel] = float(command[1])
                                        elif command[0] == 'sample':
                                                if len(command) == 2:
                                                        print(' --- sample time:', command[1])
                                                        for i in range(0, rows):
                                                                pids[i].sample_time = float(command[1])
                                        elif command[0] == 'pid':
                                                if len(command) == 4:
                                                        print(' --- set pid:', command[1], command[2], command[3])
                                                        for i in range(0, rows):
                                                                pids[i].tunings = (float(command[1]), float(command[2]), float(command[3]))
                                        elif command[0] == 'limits':
                                                if len(command) == 3:
                                                        print(' --- set limits:', command[1], command[2])
                                                        for i in range(0, rows):
                                                                pids[i].output_limits = (float(command[1]), float(command[2]))
                                        else:
                                                print(' --- unknown:', command)
                except Exception as e:
                        print(e)

                ### update PIDs
                temperatures = get_temperatures(coordinates)
                row_temperatures = get_row_temperatures(temperatures)
                for i in range(0, rows):
                        if current_setpoint[i] > target_setpoint[i]:
                                current_setpoint[i] = current_setpoint[i] - 1.
                        elif current_setpoint[i] < target_setpoint[i]:
                                current_setpoint[i] = current_setpoint[i] + 1.
                        pids[i].setpoint = current_setpoint[i]
                        if temperatures[i] == 0:
                                continue
                        pidvals[i] = int(pids[i](row_temperatures[i]))
                        pwms[i] = calibrated_pwm(i, pidvals[i])
                print(target_setpoint)
                print(current_setpoint)
                print(temperatures)
                print(row_temperatures)
                print(pidvals)
                print(pwms)
                send_pwms(pwms)

 
      
 
