#! /usr/bin/env python

import usb
#help(usb.core) 
busses = usb.busses()
for bus in busses:
  devices = bus.devices
  for dev in devices:
#    _name = usb.util.get_string(dev.dev,1024,2)  #This is where I'm having trouble
#    print "device name=",_name
    _serial = usb.util.get_string(dev.dev,64,3)  #This is where I'm having trouble
    print "serial=",_serial
    print "Device:", dev.filename
    print "  Device class:",dev.deviceClass
    print "  Device sub class:",dev.deviceSubClass
    print "  Device protocol:",dev.deviceProtocol
    print "  Max packet size:",dev.maxPacketSize
    print "  idVendor:",hex(dev.idVendor)
    print "  idProduct:",hex(dev.idProduct)
    print "  Device Version:",dev.deviceVersion
    for config in dev.configurations:
      print "  Configuration:", config.value
      print "    Total length:", config.totalLength 
      print "    selfPowered:", config.selfPowered
      print "    remoteWakeup:", config.remoteWakeup
      print "    maxPower:", config.maxPower
      for intf in config.interfaces:
        print "    Interface:",intf[0].interfaceNumber
        for alt in intf:
          print "    Alternate Setting:",alt.alternateSetting
          print "      Interface class:",alt.interfaceClass
          print "      Interface sub class:",alt.interfaceSubClass
          print "      Interface protocol:",alt.interfaceProtocol
          for ep in alt.endpoints:
            print "      Endpoint:",hex(ep.address)
            print "        Type:",ep.type
            print "        Max packet size:",ep.maxPacketSize
            print "        Interval:",ep.interval
