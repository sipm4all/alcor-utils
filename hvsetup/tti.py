#! /usr/bin/env python3

import usb.core
import usb.util
import time
import sys

dev = usb.core.find(idVendor=0x103e, idProduct=0x04d8, find_all=True)
if dev is None:
    raise ValueError('Device not found')

if len(sys.argv) == 1:
    for d in dev:
        print()
        print(d)
        print()

if (len(sys.argv)) != 5:
    print('usage: ./tti.py [address] [voltage] [current] [0/1]')
    exit()
address = int(sys.argv[1])
voltage = sys.argv[2]
current = sys.argv[3]
on = sys.argv[4]


def send_command(d, command):
    command = command + ' \n\r'
    d.write(0x2, command.encode())
    time.sleep(0.1)

def read_back(d):
    data = d.read(0x82, 64)
    val = "".join(map(chr, data))
    time.sleep(0.1)
    return val

for d in dev:
    if (d.address != address):
        continue

    if d.is_kernel_driver_active(0):
        d.detach_kernel_driver(0)
    usb.util.claim_interface(d, 0)

    # write the data
    send_command(d, 'V1 ' + voltage);
    send_command(d, 'I1 ' + current);
    send_command(d, 'OP1 ' + on);
    time.sleep(1)

    ### read back values
#    send_command(d, 'V1O?')
#    val = read_back(d)
#    print(val);

#    send_command(d, 'I1O?')
#    val = read_back(d)
#    print(val);
#    command = 'I1O? \n'

#    usb.util.release_interface(d, 0)
#    d.attach_kernel_driver(0)
