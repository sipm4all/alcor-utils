#! /usr/bin/env python

import keithley as ky
import sys
import matplotlib.pyplot as plt
import time
import datetime

### parse arguments
args = ky.parse_arguments()

### output file run tag
outfiletagname = ky.build_tagname(args)

### start
starttime = time.time()
print('--- Keithley \'transition\' program started: %s' % outfiletagname)

### add time tag
#timenow = datetime.datetime.now()
#timetag = timenow.strftime('%Y%m%d%H%M%S')
#outfiletagname += '.' + timetag

### define plots
plt.ion()
fig, ax = plt.subplots(1, 1, figsize=(5, 5))
ax.set_title('transition scan')
ax.set_xlabel('time (s)')
ax.set_ylabel('I (A)')
ax.set_ylim([-2.e-9, 2.e-9])
fig.tight_layout()

### connect and initialize
ky.connect()
ky.initialize()
ky.read_config()

#######################
### TRANSITION SCAN ###
#######################

Vscan = [0., -48.7, 0.]

### configure source and trigger model
ky.source_measure_config(Vscan = Vscan)
ky.trigger_config(Twait = 0., Tstep = 0., Tmeas = 60., Nmeas = 'INF')

### start trigger model and wait
ky.trigger_init()
ky.trigger_wait()

### read measurements
measurements = ky.read_measurements()

### plot measurements
ky.plot_measurements(measurements, 'REL', 'READ', ax, invertY = True);

### write measurements
ky.write_measurements(measurements, outfiletagname + '.transition.csv')

### write commands
ky.write_commands(outfiletagname + '.transition.scpi')

### close connection
ky.close()

### done
endtime = time.time()
print('--- Keithley \'transition\' program completed: %f seconds' % (endtime - starttime))

### wait for plot
print('--- plot is ready and saved: waiting for 5 seconds')
plt.savefig(outfiletagname + '.transition.png')
time.sleep(5)
