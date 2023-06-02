#!/usr/bin/env python3

from mlsocket import MLSocket
from simple_pid import PID
import numpy as np
import socket
import os
import socket
import struct

running = True
coordinates_file = '/au/annealing/inversa/centers.npy'
sipm = 12

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

### calibrated PWM
def calibrated_pwm(channel, value):
        channels_A = [11, 2, 8, 7]
        channels_B = [9, 10, 3, 0]
        channels_C = [1, 4, 5, 6]

        params_A = [-15.3081, 0.568639, -0.00559741, 2.19294e-05]
        params_B = [-77.9011, 3.09205, -0.0329114, 0.00013744]
        params_C = [-41.3134, 1.51146, -0.0119845, 3.59111e-05]

        params = []
        if channel in channels_A:
                params = params_A
        elif channel in channels_B:
                params = params_B
        elif channel in channels_C:
                params = params_C
                
        pwm = params[0] + params[1] * value + params[2] * value ** 2 + params[3] * value ** 3
        if pwm < 0:
                pwm = 0
        return pwm
                
### send PWM command
def send_pwms(pwms):
        SOCK='/tmp/arduino_pwm_server.socket'
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCK)
                command = 'PWM ' + ','.join(map(str, pwms))
                s.sendall(command.encode())            

### update main voltage
def update_voltage(voltage):
        print(" --- request to update voltage:", voltage)
        SOCK='/tmp/plh610_server.socket'
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCK)
                command = 'V1 ' + str(voltage)
                s.sendall(command.encode())
                data = s.recv(1024).decode()
        print(" --- done update voltage:", voltage)
                
### reset PWMs
pwms = np.zeros(sipm, dtype=int)
pidvals = np.zeros(sipm, dtype=float)
send_pwms(pwms)

### load coordinates
coordinates = np.load(coordinates_file)

### get current temperatures
temperatures = get_temperatures(coordinates)

### initialise pwm PIDs
pids = [None] * sipm
current_setpoint = np.copy(temperatures)
target_setpoint = np.copy(temperatures)
for i in range(0, sipm):
        scale = 1.
        channels_C = [1, 4, 5, 6]
        if i in channels_C:
                scale = 0.25
        pids[i] = PID(0.1 * scale, 0.05 * scale, 0.1 * scale, setpoint = current_setpoint[i])
        pids[i].sample_time = 2.
        pids[i].output_limits = (25., 250.)
        pids[i].auto_mode = True

### initialise volt PID
volt_current_setpoint = np.mean(temperatures)
volt_target_setpoint = volt_current_setpoint
volt_pid = PID(0.1, 0.05, 0.01, setpoint = current_setpoint[i])
volt_pid.sample_time = 2.
volt_pid.output_limits = (25., 40.)
        
### open socket and listen
SOCK='/tmp/arduino_pwm_control.socket'
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
                                                        for i in range(0, sipm):
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
                                                        for i in range(0, sipm):
                                                                target_setpoint[i] = float(command[1])
                                                if len(command) == 3:
                                                        channel = int(command[2])
                                                        print(' --- goto point for channel', channel, ':', command[1])
                                                        target_setpoint[channel] = float(command[1])
                                        elif command[0] == 'sample':
                                                if len(command) == 2:
                                                        print(' --- sample time:', command[1])
                                                        for i in range(0, sipm):
                                                                pids[i].sample_time = float(command[1])
                                        elif command[0] == 'pid':
                                                if len(command) == 4:
                                                        print(' --- set pid:', command[1], command[2], command[3])
                                                        for i in range(0, sipm):
                                                                scale = 1.
                                                                channels_C = [1, 4, 5, 6]
                                                                if i in channels_C:
                                                                        scale = 0.25
                                                                pids[i].tunings = (float(command[1]) * scale, float(command[2]) * scale, float(command[3]) * scale)
                                        elif command[0] == 'limits':
                                                if len(command) == 3:
                                                        print(' --- set limits:', command[1], command[2])
                                                        for i in range(0, sipm):
                                                                pids[i].output_limits = (float(command[1]), float(command[2]))
                                        else:
                                                print(' --- unknown:', command)
                except Exception as e:
                        print(e)

                ### update PIDs
                temperatures = get_temperatures(coordinates)
                for i in range(0, sipm):
                        if current_setpoint[i] > target_setpoint[i]:
                                current_setpoint[i] = current_setpoint[i] - 1.
                        elif current_setpoint[i] < target_setpoint[i]:
                                current_setpoint[i] = current_setpoint[i] + 1.
                        pids[i].setpoint = current_setpoint[i]
                        if temperatures[i] == 0:
                                continue
                        pidvals[i] = int(pids[i](temperatures[i]))
                        pwms[i] = calibrated_pwm(i, pidvals[i])
                print(target_setpoint)
                print(current_setpoint)
                print(temperatures)
                print(pidvals)
                print(pwms)
                send_pwms(pwms)

 
      
 
