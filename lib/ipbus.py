import uhal

def read(hw,regName):
    """Read content of register reg on hw node over IPBUS. Data read is returned."""
    node=hw.getNode(regName);
    reg=node.read();
    hw.dispatch();
#    print "IPBUS read  ",hex(reg) + "\tat ",regName
    return reg

def post(hw,regName,data):
    node=hw.getNode(regName);
    reg=node.write(data);
    return reg

def write(hw,regName,data):
    """Write data content of register reg on hw node over IPBUS"""
    node=hw.getNode(regName);
    reg=node.write(data);
    hw.dispatch();
#    print "IPBUS write ",hex(data) +"\tat ",regName,reg.valid()
    return reg

def rdfifo(hw,regName,n):
    """Read n data from FIFO"""
    node=hw.getNode(regName)
    buf=node.readBlock(n)
    hw.dispatch()
    return buf
