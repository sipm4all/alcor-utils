#! /usr/bin/env python

import keithley as ky
import sys
import numpy as np
import matplotlib.pyplot as plt
import datetime
import time

### parse arguments
args = ky.parse_arguments()

### output file run tag
outfiletagname = ky.build_tagname(args)

### start
starttime = time.time()
print('--- Keithley \'fwdscan\' program started: %s' % outfiletagname)

### add time tag
#timenow = datetime.datetime.now()
#timetag = timenow.strftime('%Y%m%d%H%M%S')
#outfiletagname += '.' + timetag

### define plots
plt.ion()
fig, ax = plt.subplots(1, 1, figsize=(5, 5))
ax.set_title('forward scan')
ax.set_xlabel('Vforward (V)')
ax.set_ylabel('I (A)')
fig.tight_layout()

### connect and initialize
ky.connect()
ky.initialize()
ky.read_config()

#########################
### FORWARD BIAS SCAN ###
#########################

### [0., 3.] in 100 mV steps
Vmin  = 0.
Vmax  = 3.
Vstep = 0.100
Vscan = np.arange(Vmin, Vmax, Vstep)
Vscan = np.append(Vscan, Vmax)

### configure source and trigger model
ky.send('SOUR:VOLT:RANG 20')
ky.source_measure_config(Vscan = Vscan, Ilim = 25.e-3)
ky.trigger_config(Twait = 10., Tstep = 0.5, Tmeas = 0., Nmeas = 9)

### start trigger model and wait
ky.trigger_init()
ky.trigger_wait()

### read measurements
measurements = ky.read_measurements()

### plot measurements
ky.plot_measurements(measurements, 'SOUR', 'READ', ax, invertX = False, invertY = False);

### write measurements
ky.write_measurements(measurements, outfiletagname + '.fwdscan.csv')

### write commands
ky.write_commands(outfiletagname + '.fwdscan.scpi')

### close connection
ky.close()

### done
endtime = time.time()
print('\a')
print('--- Keithley \'fwdscan\' program completed: %f seconds' % (endtime - starttime))

### wait for plot
print('--- plot is ready and saved: waiting for 5 seconds')
plt.savefig(outfiletagname + '.fwdscan.png')
time.sleep(5)

