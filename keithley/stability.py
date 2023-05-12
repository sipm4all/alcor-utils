#! /usr/bin/env python

import keithley as ky
import sys
import datetime

### parse arguments
args = ky.parse_arguments()

### hardcoded settings (valid for SensL)
Vbd = 24.5

### output file run tag
outfiletagname = ky.build_tagname(args)

### start
print('--- Keithley stability scan program started: tagname = %s' % outfiletagname)

### add time tag
timenow = datetime.datetime.now()
timetag = timenow.strftime('%Y%m%d%H%M%S')
outfiletagname += '.' + timetag

### connect and initialize
ky.connect()
ky.initialize()
ky.read_config()

######################
### STABILITY SCAN ###
######################

Vscan = [-20.]
ky.source_config(Vscan = Vscan)
ky.trigger_config(Twait = 0., Tstep = 0., Tmeas = 300., Nmeas = 'INF')

### continuous scan
while True:

    ### start trigger model and wait
    ky.trigger_init()
    ky.trigger_wait()

    ### read measurements and append to file
    measurements = ky.read_measurements()
    ky.write_measurements(measurements, outfiletagname + '.stability.csv', 'a+')

ky.close()
