#! /usr/bin/env python3

from flask import Flask, render_template, request, redirect
import os

app = Flask(__name__)

def isfloat(num):
    try:
        float(num)
        return True
    except ValueError:
        return False

@app.route('/alarm', methods=['POST'])
def alarm():
    if request.method == 'POST':
        os.system('/au/peltier-bologna/peltier_pid_control_client.py \"alarm fired\"')
    else:
        print('invalid')
    return 'got it'
        


@app.route('/masterlogic/<masterlogic_name>/<masterlogic_number>', methods=['GET', 'POST'])
def masterlogic(masterlogic_name=None, masterlogic_number=None):
    themessage = 'ready to accept commands: {}'.format(masterlogic_name)
    # handle the POST request
    if request.method == 'POST':
        print(request.form)

        voltage = request.form.get('voltage')
        voltage_set = request.form.get('voltage_set')
        if voltage_set == 'zero':
            themessage = 'setting voltage to ZERO'
            os.system('/au/masterlogic/zero {} &'.format(masterlogic_number))
        elif isfloat(voltage):
            themessage = 'setting voltage to {}: {} V'.format(voltage_set, voltage)
            os.system('/au/masterlogic/voltage_set.sh {} {} {} {} &'.format(masterlogic_number, masterlogic_name, voltage, voltage_set))
                
        return render_template('masterlogic.html', message=themessage, name=masterlogic_name, number=masterlogic_number)

    # otherwise handle the GET request
    return render_template('masterlogic.html', message=themessage, name=masterlogic_name, number=masterlogic_number)

@app.route('/', methods=['GET', 'POST'])
def form_example():
    themessage = 'ready to accept commands'
    # handle the POST request
    if request.method == 'POST':
        print(request.form)
        alcor = request.form.get('alcor')
        if alcor == 'on':
            themessage = 'ALCOR power turned ON'
            os.system('/au/tti/alcor.on &')
        elif alcor == 'off':
            themessage = 'ALCOR power turned OFF'
            os.system('/au/tti/alcor.off &')
        elif alcor == 'init':
            themessage = 'ALCOR init executed'
            os.system('/au/control/alcorInit.sh 666 /tmp &')
        elif alcor == 'calib':
            themessage = 'ALCOR baseline calibration started'
            os.system('/au/measure/readout-box/run-box-baseline-calibration.sh &')
        elif alcor == 'firmw':
            themessage = 'KC705 firmare check executed'
            os.system('/au/firmware/check_kc705.sh &')
            
        hv = request.form.get('hv')
        if hv == 'on':
            themessage = 'HV turned ON'
            os.system('/au/tti/hv.on')
        elif hv == 'off':
            themessage = 'HV turned OFF'
            os.system('/au/tti/hv.off')

        temperature = request.form.get('temperature')
        pid_temperature = request.form.get('pid_temperature')
        if isfloat(temperature):
            if pid_temperature == 'goto':
                themessage = 'PELTIER control setpoint temperature goto: {}'.format(temperature)
                os.system('/au/peltier-bologna/peltier_pid_control_client.py \"goto {}\" &'.format(temperature))
            elif pid_temperature == 'set':
                themessage = 'PELTIER control setpoint temperature set: {}'.format(temperature)
                os.system('/au/peltier-bologna/peltier_pid_control_client.py \"set {}\" &'.format(temperature))
                
            
        peltier_power = request.form.get('peltier_power')
        if peltier_power == 'on':
            themessage = 'PELTIER power turned ON'
            os.system('/au/peltier-bologna/peltier.on')
        elif peltier_power == 'off':
            themessage = 'PELTIER power turned OFF'
            os.system('/au/peltier-bologna/peltier.off')
            
        peltier_alarm = request.form.get('peltier_alarm')
        if peltier_alarm == 'on':
            themessage = 'PELTIER alarm turned ON'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"alarm on\" &')
        elif peltier_alarm == 'off':
            themessage = 'PELTIER alarm turned OFF'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"alarm off\" &')

            
        pid_control = request.form.get('pid_control')
        if pid_control == 'on':
            themessage = 'PELTIER control turned ON'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"on\" &')
        elif pid_control == 'off':
            themessage = 'PELTIER control turned OFF'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"off\" &')
            
        pid_anchor = request.form.get('pid_anchor')
        if pid_anchor == 'average':
            themessage = 'PELTIER anchor point set: average'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"anchor average\" &')
        elif pid_anchor == 'temp-0':
            themessage = 'PELTIER anchor point set: temp-0'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"anchor ml0\" &')
        elif pid_anchor == 'temp-1':
            themessage = 'PELTIER anchor point set: temp-1'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"anchor ml1\" &')
        elif pid_anchor == 'temp-2':
            themessage = 'PELTIER anchor point set: temp-2'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"anchor ml2\" &')
        elif pid_anchor == 'temp-3':
            themessage = 'PELTIER anchor point set: temp-3'
            os.system('/au/peltier-bologna/peltier_pid_control_client.py \"anchor ml3\" &')
        return render_template('home.html', message=themessage)

    # otherwise handle the GET request
    return render_template('home.html', message=themessage)

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=31000)
