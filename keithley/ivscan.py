#! /usr/bin/env python

import keithley as ky
import sys
import numpy as np
import matplotlib.pyplot as plt
import datetime
import time

ion = False

### parse arguments
args = ky.parse_arguments()

### output file run tag
outfiletagname = ky.build_tagname(args)

### start
starttime = time.time()
print('--- Keithley \'ivscan\' program started: %s' % outfiletagname)

### Vbd reference values from datasheet
Vbd_refV = {'SENSL' : 24.5  , 'BCOM' : 26.9  , 'FBK' : 32.0  , 'HAMA1' : (53.0 - 2.) , 'HAMA2' : 38.0  , 'HAMA3' : 51.0  }
Vbd_refT = {'SENSL' : 21.0  , 'BCOM' : 25.0  , 'FBK' : 24.0  , 'HAMA1' : 25.0        , 'HAMA2' : 25.0  , 'HAMA3' : 25.0  }
Vbd_coef = {'SENSL' : 0.021 , 'BCOM' : 0.025 , 'FBK' : 0.035 , 'HAMA1' : 0.054       , 'HAMA2' : 0.034 , 'HAMA3' : 0.054 }

### temperature dependent optimisation
NaverT = {293 : 1 , 283 : 1 , 273 : 2 , 263 : 2 , 253 : 4 , 243 : 1} # R+HACK
#NaverT = {293 : 1 , 283 : 1 , 273 : 2 , 263 : 2 , 253 : 4 , 243 : 4}
Naver = NaverT[args.temperature]

### calculate expected Vbd
refV = Vbd_refV[args.board]
refT = Vbd_refT[args.board]
coef = Vbd_coef[args.board]
if args.board == 'HAMA3' and args.channel in ['C1', 'C2', 'C3', 'C4', 'OPEN-C1', 'OPEN-C2', 'OPEN-C3', 'OPEN-C4']:
    refV = Vbd_refV['HAMA2']
    refT = Vbd_refT['HAMA2']
    coef = Vbd_coef['HAMA2']
    
Vbd = refV + coef * (args.temperature - 273 - refT)
print('--- calculate expected Vbd for {board} at T = {temperature} K'.format(board = args.board, temperature = args.temperature))
print('--- Vbd = {Vbd} V (refV = {refV}, refT = {refT}, coef = {coef})'.format(Vbd = Vbd, refV = refV, refT = refT, coef = coef))
Vbd = round(Vbd, 1)
print('--- rounding at first decimal: Vbd = {Vbd}'.format(Vbd = Vbd))

### add time tag
#timenow = datetime.datetime.now()
#timetag = timenow.strftime('%Y%m%d%H%M%S')
#outfiletagname += '.' + timetag

### define plots
if ion:
    plt.ion()
fig, ax = plt.subplots(1, 1, figsize=(5, 5))
ax.set_title('IV scan')
ax.set_xlabel('Vbias (V)')
ax.set_ylabel('I (A)')
ax.set_yscale('log')
fig.tight_layout()

### connect and initialize
ky.connect()
ky.initialize()
ky.read_config()

#########################
### REVERSE BIAS SCAN ###
#########################

### [Vbd - 2, Vbd + 10] in 200 mV steps
Vmin  = Vbd - 2.
Vmax  = Vbd + 15.
Vstep = args.vstep;
Vscan = np.arange(Vmin, Vmax, Vstep)
Vsmart = [Vbd, Vbd + 5.]

### configure source, measure and trigger model
ky.source_measure_config(Vscan = Vscan, Ilim = 250.e-6, reverse = True, Vsmart = Vsmart, Naver = Naver)
ky.trigger_config(Twait = args.twait, Tstep = args.tstep, Tmeas = 0., Nmeas = args.nmeas)

### start trigger model and wait
ky.trigger_init()
ky.trigger_wait()

### read measurements
measurements = ky.read_measurements()

### plot measurements
ky.plot_measurements(measurements, 'SOUR', 'READ', ax, invertX = True, invertY = True);

### write measurements
ky.write_measurements(measurements, outfiletagname + '.ivscan.csv')

### write commands
ky.write_commands(outfiletagname + '.ivscan.scpi')

### close connection
ky.close()

### done
endtime = time.time()
print('\a')
print('--- Keithley \'ivscan\' program completed: %f seconds' % (endtime - starttime))

### wait for plot
print('--- plot is ready and saved: waiting for 5 seconds')
plt.savefig(outfiletagname + '.ivscan.png')
time.sleep(5)
