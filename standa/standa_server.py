#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import serial
import argparse
import os
import time

parser = argparse.ArgumentParser()
parser.add_argument('--axis', type=int, choices=[1, 2], required=True, help="axis number")
args = vars(parser.parse_args())

SOCK='/tmp/standa_server.axis' + str(args['axis']) + '.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)    

DEV='/dev/STANDA' + str(args['axis'])
if not os.path.exists(DEV):
  print(' --- device not found:', DEV);
  exit(1)
  
ser = serial.Serial(port=DEV, baudrate=115200, stopbits=serial.STOPBITS_TWO, timeout=1)
print(' --- serial connection opened:', DEV)

locked = False

def compute_crc(data):
  crc = 0xffff  
  for byte in data:
    crc = crc ^ byte
    for bit in range(0, 8):
      a = crc
      carry_flag = a & 0x0001
      crc = crc >> 1
      if carry_flag == 1:
        crc = crc ^ 0xa001
  return crc.to_bytes(2, byteorder='little')

def int_from_bytes(data):
  return int.from_bytes(data, signed=True, byteorder='little')

def uint_from_bytes(data):
  return int.from_bytes(data, signed=False, byteorder='little')

def gets():
  ser.write('gets'.encode())
  data = ser.read(54)
  retval = {}
  retval['MoveSts'] = data[4]
  retval['MvCmdSts'] = data[5]
  retval['PWRSts'] = data[6]
  retval['EncSts'] = data[7]
  retval['WindSts'] = data[8]
  retval['CurPosition'] = int_from_bytes(data[9:12])
  retval['uCurPosition'] = int_from_bytes(data[13:14])
  retval['EncPosition'] = int_from_bytes(data[15:22])
  retval['CurSpeed'] = int_from_bytes(data[23:26])
  retval['uCurSpeed'] = int_from_bytes(data[27:28])
  retval['lpwr'] = uint_from_bytes(data[29:30])
  retval['Upwr'] = uint_from_bytes(data[31:32])
  retval['lusb'] = uint_from_bytes(data[33:34])
  retval['Uusb'] = uint_from_bytes(data[35:36])
  retval['CurT'] = uint_from_bytes(data[37:38])
  retval['Flags'] = uint_from_bytes(data[39:42])
  retval['GPIOFlags'] = uint_from_bytes(data[43:46])
  retval['CmdBufFreeSpace'] = data[47]
  retval['Reserved'] = int_from_bytes(data[48:51])
  retval['CRC'] = int_from_bytes(data[52:53])
  return retval

def rest():
  if locked:
    return 'locked'
  ser.write('rest'.encode())
  data = ser.read(4)
  return data.decode()

def home():
  if locked:
    return 'locked'
  ser.write('home'.encode())
  data = ser.read(4)
  return data.decode()

def zero():
  if locked:
    return 'locked'
  ser.write('zero'.encode())
  data = ser.read(4)
  return data.decode()
  
def stop():
  if locked:
    return 'locked'
  ser.write('stop'.encode())
  data = ser.read(4)
  return data.decode()
  
def move(pos):
  if locked:
    return 'locked'
  pos = pos.to_bytes(4, signed=True, byteorder='little')
  upos = bytearray(2)
  res = bytearray(6)
  data = b'move' + pos + upos + res
  data += compute_crc(data[4:])
  ser.write(data)
  data = ser.read(4)
  return data.decode()
    
def movr(delta):
  if locked:
    return 'locked'
  delta = delta.to_bytes(4, signed=True, byteorder='little')
  udelta = bytearray(2)
  res = bytearray(6)
  data = b'movr' + delta + udelta + res
  data += compute_crc(data[4:])
  ser.write(data)
  data = ser.read(4)
  return data.decode()

def wait():
  while gets()['MvCmdSts'] & 0x80: # wait till we are moving
    time.sleep(0.01)  
  return 'wait'

def lock():
  global locked
  locked = True
  return 'lock'

def unlock():
  global locked
  locked = False
  return 'unlock'

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
                    command = command.split()
                    if command[0]   == 'lock':   data = lock()
                    elif command[0] == 'unlock': data = unlock()
                    elif command[0] == 'rest':   data = rest()
                    elif command[0] == 'home':   data = home()
                    elif command[0] == 'zero':   data = zero()
                    elif command[0] == 'stop':   data = stop()
                    elif command[0] == 'gpos':   data = str(gets()['CurPosition'])
                    elif command[0] == 'move':   data = move(int(command[1]))
                    elif command[0] == 'movr':   data = movr(int(command[1]))
                    elif command[0] == 'wait':   data = wait()
                    elif command[0] == 'gets':
                      if len(command) == 1:      data = str(gets())
                      else:                      data = str(gets()[command[1]])
                    else:                        data = 'error'
                    print('--- sending data:', data)
                    conn.sendall(data.encode())
    except Exception as e:
      print(e)

ser.close()
