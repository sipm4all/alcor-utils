#!/usr/bin/env python3

import socket
import time
import sys
import signal
import os

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

timedout = 0
control_old = None
setpoint_old = None
which_temp_old = None

alarm_mode = 'off'

alarm_map = { 'off': 0, 'on': 1, 'fired': 2 }
anchor_map = { 'average': 0, 'lowest': 1, 'highest': 2, 'ml0':3, 'ml1':4, 'ml2': 5, 'ml3': 6 }

SOCK='/tmp/peltier_pic_control.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

SOCKTSX = '/tmp/tsx1820p_server.socket'
SOCKML = ['/tmp/masterlogic_server.ML' + str(x) + '.socket' for x in range(0,1)]
SOCKARDUINO = '/tmp/arduino_server.socket'

which_temp = 'ml0'


def get_dewpoint():
   with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKARDUINO)
        command = 'dew'
        s.sendall(command.encode())
        data = s.recv(1024).decode()
        return float(data)

def get_temperature():
    temp = [0, 0, 0, 0]
    thetemp = {}
    for ml in range(0,1):
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCKML[ml])
            s.sendall(b'L')
            temp[ml] = float(s.recv(1024).decode().split()[2])
    thetemp['average'] = sum(temp) / 4.
    thetemp['lowest'] = min(temp)
    thetemp['highest'] = max(temp)
    thetemp['ml0'] = temp[0]
    thetemp['ml1'] = temp[1]
    thetemp['ml2'] = temp[2]
    thetemp['ml3'] = temp[3]
    print(" --- get temperature", thetemp[which_temp])
    return thetemp[which_temp]

def update_current(current):
    print(" --- request to update current:", current)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKTSX)
        command = 'I1 ' + str(current)
        s.sendall(command.encode())
        data = s.recv(1024).decode()
    print(" --- done update current:", current)

def do_alarm():
  print(" --- executing alarm sequence ")
  global current_control
  current_control = 0
  pid.auto_mode = False
  with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCKTSX)
    command = 'I1 0.01'
    s.sendall(command.encode())
    data = s.recv(1024).decode()
    command = 'OP1 0'
    s.sendall(command.encode())
    data = s.recv(1024).decode()  
    
def get_current():
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKTSX)
        command = 'I1O?'
        s.sendall(command.encode())
        data = s.recv(1024).decode()
#        current = float(data.split()[1])
        current = float(data[:-1])
    print(" --- get current", current)
    return current

current_control = 0
target_setpoint = round(get_temperature(), 3)
current_setpoint = target_setpoint
  
from simple_pid import PID
pid = PID(-0.4, -0.002, -0.2, setpoint = current_setpoint)
pid.output_limits = (0.01, 5.)
pid.sample_time = 3.

pid.auto_mode = False

# turn on PID control at start-up
current = get_current()
pid.set_auto_mode(True, last_output = current)
current_control = 1

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:

    s.bind(SOCK)
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
            print(' --- received command:', command)
            command = command.split()
            if command[0] == 'on':
              current_control = 1
              target_setpoint = round(get_temperature(), 3)
              current_setpoint = settarget_setpoint
              pid.setpoint = current_setpoint
              print(' --- set point:', current_setpoint)
              current = get_current()
              pid.set_auto_mode(True, last_output = current)
              print(' --- auto mode: on')
            elif command[0] == 'off':
              current_control = 0
              print(' --- auto mode: off')
              pid.auto_mode = False
            elif command[0] == 'alarm':
              if len(command) == 2 and command[1] in ('on', 'off', 'fired'):
                if command[1] == 'fired' and alarm_mode == 'on':
                  do_alarm()
                alarm_mode = command[1]
                print(' --- alarm mode:', command[1])
            elif command[0] == 'anchor':
              if len(command) == 2 and command[1] in ('average', 'highest', 'lowest', 'ml0', 'ml1', 'ml2', 'ml3'):
                print(' --- anchor point:', command[1])
                which_temp = command[1]
            elif command[0] == 'set':
              if len(command) == 2:
                target_setpoint = float(command[1])
                current_setpoint = target_setpoint
                pid.setpoint = float(current_setpoint)
                print(' --- set point:', current_setpoint)
            elif command[0] == 'goto':
              if len(command) == 2:
                print(' --- goto point:', command[1])
                current_setpoint = round(get_temperature(), 3)
                target_setpoint = float(command[1])
            elif command[0] == 'sample':
              if len(command) == 2:
                print(' --- sample time:', command[1])
                pid.sample_time = float(command[1])
            elif command[0] == 'pid':
              if len(command) == 4:
                print(' --- set pid:', command[1], command[2], command[3])
                pid.tunings = (float(command[1]), float(command[2]), float(command[3]))
            elif command[0] == 'limits':
              if len(command) == 3:
                print(' --- set limits:', command[1], command[2])
                pid.output_limits = (float(command[1]), float(command[2]))
            else:
              print(' --- unknown:', command)
      except Exception as e:
        print(e)

      if current_setpoint > target_setpoint:
        current_setpoint = current_setpoint - 0.05
        if current_setpoint < target_setpoint:
          current_setpoint = target_setpoint
      elif current_setpoint < target_setpoint:
        current_setpoint = current_setpoint + 0.05
        if current_setpoint > target_setpoint:
          current_setpoint = target_setpoint

      current_dewpoint = get_dewpoint()
      print('current dewpoint =', current_dewpoint)
      current_setpoint = max(current_setpoint, current_dewpoint + 5.)
          
      current_setpoint = round(current_setpoint, 3)
      pid.setpoint = float(current_setpoint)
      print(' --- set point:', current_setpoint)


      if True or current_control != control_old or current_setpoint != setpoint_old or which_temp != which_temp_old or timedout > 100:
        control_old = current_control
        setpoint_old = current_setpoint
        which_temp_old = which_temp
        thedata = 'peltier_pid_control,source=peltier,name=CTRL value=' + str(current_control) + '\n'
        thedata += 'peltier_pid_control,source=peltier,name=ALARM value=' + str(alarm_map[alarm_mode]) + '\n'
        thedata += 'peltier_pid_control,source=peltier,name=TSET value=' + str(current_setpoint) + '\n'
        thedata += 'peltier_pid_control,source=peltier,name=ANCHOR value=' + str(anchor_map[which_temp])
        print(thedata)
        session.post(url, data=thedata.encode())
        timedout = 0
      timedout += 1

#      if current_control == 0:
#        continue
      
      # Compute new output from the PID according to the systems current value
      v = get_temperature()
      control = pid(v)
      if control is None:
        continue
      control = round(control, 2)
      update_current(control);

