#!/bin/env python

import argparse

# -*- coding: utf-8 -*-
from Tkinter import *
#from Tkinter import filedialog as fd
from ctypes import *
from datetime import datetime
import os
from contextlib import contextmanager
import ttk  
from tkFileDialog import *
import time
import platform, sys

# for IPBUS
import uhal
# for ALCOR
#import spi
import alcor as alc
import ipbus

actWrd={alc.RDREG:'Expected',alc.SETREG:'Setting'}

#@contextmanager
def stdout_redirector(stream):
    old_stdout = sys.stdout
    sys.stdout = stream
    try:
        yield
    finally:
        sys.stdout = old_stdout



#  define parser
my_parser = argparse.ArgumentParser(description='GUI Interface to ALCOR')
my_parser.add_argument('ConnFile',metavar='IPBUS connection',type=str,help='XML file')
my_parser.add_argument('CardId',metavar='CARD Id',type=str,help='XML file')
args = my_parser.parse_args()

# Creating the HwInterface
connectionMgr = uhal.ConnectionManager("file://" + args.ConnFile)
hw = connectionMgr.getDevice(args.CardId)


root = Tk()

root.title("ALCOR Setup")
root.geometry("250x100")
root.resizable(False, False)
allreadw = None
gbtxallr = None
          
frame0= Frame(root, bd=2, relief=SUNKEN)
frame0.pack(pady=5)
chipt= Label(frame0, text='Select target ALCOR chip')
chipt.pack()
chips= IntVar()
chips.set(0)
for i in range(0,6):
    b = Radiobutton(frame0, text=i, variable=chips, value= i)
    b.pack(side=LEFT)

# Global Variables
bcrr = [StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar()]
eccr = [StringVar(),StringVar(),StringVar(),StringVar()]
pcrr = [StringVar(),StringVar(),StringVar(),StringVar()]
chTarget = StringVar()
valCtrl = StringVar()
valEnc = StringVar()
valStat = StringVar()
valMode = StringVar()
valFW = StringVar()
inputFile = StringVar()

cmenu = None    # This the Chip Main menu

saveText = StringVar()
textread = None
textreadgbtx = None

frame = Frame(root, borderwidth= 10)
checkt = False
#temp = None
var = IntVar()
avar = IntVar()
avars = IntVar()
entrysave = None
ts = [StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar(),StringVar()]


def oclose():
    global hw
    global var
    global chips
    if var.get() == 1:
        ad=1
        rw=0
        spiData=0
#        data=alc.programPtrReg(hw,alc.BCR,ad,spiData,alc.RDREG)
#        print "Value Read at at BCR 0 ",hex(data&0xFFFF)
        openIpbus=1
    elif var.get() == 0:
        closeIpbus=1
        
def saveT():
    global ts
    global saveText
    texts = ['Time','TempGBT','TempLD0GBT','TempLD0SDES','TempPXL','TempLD0FPGA','TempIGLOO2','TempVTRX','SFPTemp','SFPVolt','SFPBias','SFPTXPow','SFPRXPow','VDD33_VME_PS','VP25T_VTRX','VP15X_GBTX','VP15D_GBTX','VP15F_FPGA_Bank7','VP12F_FPGA_CORE','VP25E_FPGA_Bank1,5,9','VP25R_RAM_I/O']
    with open(saveText.get(),'a') as p:
        if os.path.getsize(saveText.get()) == 0:
            for i in range(0,21):
            	if i ==0:
                	p.write('%-22s' % (texts[i]))
                else:
                	a = '%-'+str(len(texts[i])+2)+'s'
                	p.write(a % (texts[i]))                
                if i ==20:
                    p.write("\n")   
        p.write('%-22s' % (datetime.now().strftime("%d-%m-%Y %H:%M:%S")))
        for n in range(0,20):
            z = '%-'+str(len(texts[n+1])+2)+'s'
            p.write(z % (ts[n].get()))
            if n ==19:
                p.write("\n")        
        
def closew():
    cmenu.destroy()
    if allreadw != None:
        allreadw.destroy()

def getTs():
    global ts
    regt = [c_ulong(0x52),c_ulong(0x53),c_ulong(0x54),c_ulong(0x55),c_ulong(0x56),c_ulong(0x57),c_ulong(0x58),c_ulong(0x59),c_ulong(0x5A),c_ulong(0x5B),c_ulong(0x5C),c_ulong(0x5D), c_ulong(0x4A), c_ulong(0x4B), c_ulong(0x4C)]
    data = [c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint(),c_uint()] 
    for i in range(0,13):
        if i <= 11:    
            libDRM.drmReadRegister(regt[i],byref(data[i]))
            if i <= 7:
              ts[i].set((data[i].value)/2.)
            elif i == 8:
              ts[i].set(round((data[i].value)*0.0128,3))       
            elif i == 9:
              ts[i].set(round((data[i].value)*0.256,3))
            elif i == 10:
              ts[i].set(round((data[i].value)*0.0128,3))
            elif i == 11:
              ts[i].set(round((data[i].value)*0.0128,3))  
        elif i == 12:
            for a in range(0,9):
                libDRM.drmWriteRegister(regt[i],a)    
                libDRM.drmReadRegister(regt[13],byref(data[13]))
                libDRM.drmReadRegister(regt[14],byref(data[14]))  
                if a < 8:
                    ts[i+a].set(round(((data[14].value*(16**2))+data[13].value)/200.,3))           
                elif a==8:
                    esa = hex(int((data[14].value*(16**2))+data[13].value)).split('x')[-1].upper()
                    ts[i+a].set(esa)

def readf(reg):
    readata = [c_uint()]
    libDRM.drmReadRegister(reg,byref(readata[0]))
    text ='The register returns the value '
    text += hex(int(readata[0].value)).upper()
    return text

def readhex(reg):
    readata = [c_uint()]
    libDRM.drmReadRegister(reg,byref(readata[0]))
    text = hex(int(readata[0].value)).upper()
    return text
    
def writevals(reg, vals):
    readataw = [c_uint()]
    libDRM.drmWriteRegister(reg,vals)
    libDRM.drmReadRegister(reg,byref(readataw[0]))
    return readataw[0].value    

def autos():
    global cmenu
    global avars
    global entrysave
    if avars.get()==1:
        saveT()
        entrysave.config(state='disabled')    
    else:  
        pass
        entrysave.config(state='normal')       
    cmenu.after(10000,autos)          

def autogetTs():
    global cmenu
    global avar
    if avar.get()==1:
        getTs()    
    else:  
        pass    
    cmenu.after(2000,autogetTs)          

checksum = 0

def readFW():
    global hw
    global valFW
    data=ipbus.read(hw,"regfile.fwrev")
    valFW.set(str(hex(data&0xFFFFFFFF)))

def readMode():
    global hw
    global valMode
    data=alc.readMode(hw)
#    print "READ MODE ",hex(data)
    valMode.set(str(hex(data&0xFFFF)))

def setMode():
    global hw
    global valMode
    d=int(valMode.get(),16)
    data=alc.setMode(hw,d)
    data=alc.readMode(hw)

def readALREG(regType):
    global bcrr
    global eccr
    global pcr
    global chTarget
    global chips
    global hw
    d=0
    chip=chips.get()
    for ad in range(alc.regNr[regType]):
        if (regType == alc.PCR):
            ch = int(chTarget.get(),10)
            reg = ((ch&0x3C)<<3) | ((ch&0x3)<<2) | ad
        else:
            ch=0
            reg = ad
        data=alc.programPtrReg(hw,chip,regType,reg,d,alc.RDREG)
        print "READ ",hex(data),ch,hex(reg)
        if (regType == alc.BCR): 
            bcrr[ad].set(str(hex(data&0xFFFF)))
        elif (regType == alc.ECCR): 
            eccr[ad].set(str(hex(data&0xFFFF)))
        elif (regType == alc.PCR): 
            pcrr[ad].set(str(hex(data&0xFFFF)))

def rawMode(flag):
    global hw
    global chips
    global eccr
# we read values so eccr is updated
    readALREG(alc.ECCR)
    for ad in range(alc.regNr[alc.ECCR]):
        d=int(eccr[ad].get(),16)
        if flag == 0:
            d=alc.clear_bit(d,alc.ECCR_RAWMODE_Bit)
        elif flag == 1:
            d=alc.set_bit(d,alc.ECCR_RAWMODE_Bit)
        data=alc.programPtrReg(hw,chips.get(),alc.ECCR,ad,d,alc.SETREG)
        eccr[ad].set(str(hex(data&0xFFFF)))

def loadALREG(regType):
    global bcrr
    global eccr
    global hw
    global chips
    ch=0
    for ad in range(alc.regNr[regType]):
        if (regType == alc.BCR): 
            d=int(bcrr[ad].get(),16)
            reg=ad
        elif (regType == alc.ECCR): 
            d=int(eccr[ad].get(),16)
            reg=ad
        elif (regType == alc.PCR):
            d=int(pcrr[ad].get(),16)
            ch = int(chTarget.get(),10)
            reg = ((ch&0x3C)<<3) | ((ch&0x3)<<2) | ad
        print "LOAD ",hex(d),ch,hex(reg)
        data=alc.programPtrReg(hw,chips.get(),regType,reg,d,alc.SETREG)
    readALREG(regType)

def ctrlSeq():
    global inputFile
    global chips
    print "INPFILE: ",inputFile.get()
    alc.loadSequence(hw,chips.get(),inputFile.get())

def resetALCOR():
    global chips
    alc.reset(hw,chips.get())

def setupALCOR():
    global chips
    alc.setup(hw,chips.get(),alc.PIX_DEFAULT,alc.PIX_MASK_DEFAULT)

def initALCOR():
    global chips
    alc.init(hw,chips.get())

def chipMenu():
    global cmenu
    global var
    global avar
    global saveText
    global entrysave
#    global valCtrl
#    global cmdOptList

    chTarget.set('0')

    cmenu = Toplevel(root)
    nb = ttk.Notebook(cmenu)
    page5 = ttk.Frame(nb)
    nb.add(page5, text='Control') 
    page1 = ttk.Frame(nb)
    nb.add(page1, text='Bias') 
    page2 = ttk.Frame(nb)
    nb.add(page2, text='End of Columm') 
    page3 = ttk.Frame(nb)
    nb.add(page3, text='Pixel') 
    page4 = ttk.Frame(nb)
    nb.add(page4, text='DAQ') 

    nb.pack()        

    cmenu.resizable(False, False)
    cmenu.geometry("600x400")
    cmenu.title("ALCOR Configuration Manager [chip # "+ str(chips.get())+"]")
    

# Design all tabs
# page5 is CONTROL
    frabctrl = Frame(page5, bd=2, relief=GROOVE)
    frabctrl.grid(row=2, columnspan=1,sticky=N+W)
    framebCtrl = Frame(page5)
    framebCtrl.grid(row=3, column=0, sticky=S+W)
    framebInit = Frame(page5)
    framebInit.grid(row=3, column=1, sticky=S+W)
    framebReset = Frame(page5)
    framebReset.grid(row=3, column=2, sticky=S+W)
    framebCtrlSeq = Frame(page5)
    framebCtrlSeq.grid(row=4,column=0,stick=S+W)
    framebCtrlSeq2 = Frame(page5)
    framebCtrlSeq2.grid(row=4,column=2,stick=S+W)

    framebCmd = Frame(page5)
    framebCmd.grid(row=5, column=0, sticky=S+W)
    framebCmd2 = Frame(page5)
    framebCmd2.grid(row=5, column=1, sticky=S+W)

    framebCmdVal = Frame(page5)
    framebCmdVal.grid(row=6, column=0, sticky=S+W)

    framebCmdEnc = Frame(page5)
    framebCmdEnc.grid(row=7, column=0, sticky=S+W)
    framebCmdStat = Frame(page5)
    framebCmdStat.grid(row=7, column=1, sticky=S+W)

# page 1: Bias Control Registers
    frabcr = Frame(page1, bd=2, relief=GROOVE)
    frabcr.grid(row=2, sticky=N+W)
    framebut = Frame(page1)
    framebut.grid(row=2, column=2, sticky=S+W)

# page 2: End of Column Registers
    fraeccr = Frame(page2, bd=2, relief=GROOVE)
    fraeccr.grid(row=0, sticky=N+W)
    framebE = Frame(page2)
    framebE.grid(row=2, column=2, sticky=S+W)

# page 3: Pixel Registers
    frapcr = Frame(page3, bd=2, relief=GROOVE)
    frapcr.grid(row=0, sticky=N+W)
    framebP = Frame(page3)
    framebP.grid(row=2, column=2, sticky=S+W)

# page 4: DAQ
    fradaq = Frame(page4, bd=2, relief=GROOVE)
    fradaq.grid(row=0, sticky=N+W)
    framedaqResetFifo = Frame(page4)
    framedaqResetFifo.grid(row=3, column=0, sticky=S+W)

    framedaqFW = Frame(page4)
    framedaqFW.grid(row=4,column=0,sticky=S+W)
    framedaqFWVal = Frame(page4)
    framedaqFWVal.grid(row=4,column=1,sticky=S+W)

    framedaqMode = Frame(page4)
    framedaqMode.grid(row=5, column=0, sticky=S+W)
    framedaqModeVal = Frame(page4)
    framedaqModeVal.grid(row=5, column=1, sticky=S+W)
    framedaqModeRead = Frame(page4)
    framedaqModeRead.grid(row=5, column=2, sticky=S+W)
    framedaqModeSet = Frame(page4)
    framedaqModeSet.grid(row=5, column=3, sticky=S+W)


#  DAQ Menu  -- in future will set/start readout
    tDAQ = Label(fradaq, text='ALCOR DAQ Control', font='Helvetica 14 bold')
    tDAQ.pack()
    bResetFifo = Button(framedaqResetFifo,text = 'Reset Fifo', command = lambda: alc.resetFifo(hw,chips.get()))
    bResetFifo.pack()

    daqFWLab=Label(framedaqFW,text='Firmware Revision')
    readFW()
    daqFW=Entry(framedaqFWVal,textvariable=valFW)
    daqFWLab.pack()
    daqFW.pack()
    
    daqModeLab=Label(framedaqMode,text='Mode')
    readMode()
    daqMode=Entry(framedaqModeVal,textvariable=valMode)
    daqModeLab.pack()
    daqMode.pack()

    daqModeRead = Button(framedaqModeRead, text = 'Read', command = readMode)
    daqModeRead.pack()
    daqModeSet = Button(framedaqModeSet, text = 'Set', command = setMode)
    daqModeSet.pack()




# Control Menu -- include commands to ALCOR controller
    tCTRL = Label(frabctrl, text='ALCOR General Control', font='Helvetica 14 bold')
    tCTRL.pack()
    bLoadDef = Button(framebCtrl, text = 'Load Conf', command = setupALCOR)
    bLoadDef.pack()

    bLoadInit = Button(framebInit, text = 'Init and align', command = initALCOR)
    bLoadInit.pack()

    bLoadReset = Button(framebReset, text = 'Hard Reset', command = resetALCOR)
    bLoadReset.pack()

    bLoadSeq = Button(framebCtrlSeq, text = 'Load Sequence', command = ctrlSeq)
    bLoadSeq.pack()
    LabelFileSeq=Label(framebCtrlSeq,text='Input file')
    inputFile.set("alcor.cfg")
    LabelFileSeqValue=Entry(framebCtrlSeq,textvariable=inputFile)
    LabelFileSeqValue.pack()

    selectedOpt=StringVar(framebCmd)
    selectedOpt.set("Select a command")
    option_menu = OptionMenu(framebCmd,selectedOpt,*alc.cmdOptList)
    option_menu.pack()

    labValue=Label(framebCmdVal,text='Parameter')
    valCtrl.set("0x0")
    val=Entry(framebCmdVal,textvariable=valCtrl)
    labValue.pack()
    val.pack()

    labEnc=Label(framebCmdEnc,text='Encoded Command')
    valEnc.set("0x0")
    valEncW=Entry(framebCmdEnc,textvariable=valEnc)
    labEnc.pack()
    valEncW.pack()

    labStatus=Label(framebCmdStat,text='Status')
    valStat.set("0x0")
    stat=Entry(framebCmdStat,textvariable=valStat)
    labStatus.pack()
    stat.pack()

    def execute_ctrl():
        global valStat
        global valEnc
        global chips
#        print("Selected Option: {}",format(selectedOpt.get()))
#        print("Command is ",hex(alc.cmdList[selectedOpt.get()]))
        encData=alc.encodeCtrl(alc.cmdList[selectedOpt.get()],valCtrl.get())
        valEnc.set(str(hex(encData)))
        stat=alc.ctrl(hw,chips.get(),encData)
        valStat.set(str(hex(stat)))
        print hex(stat)
        return None

    submitCmd = Button(framebCmd2,text='Submit',command=execute_ctrl)
    submitCmd.pack()


# BCR Menu
    tBCR = Label(frabcr, text='Bias Configuration Registers', font='Helvetica 14 bold')
    tBCR.pack()
    for i in range(alc.BCRregs):
        labl = Label(frabcr,text='BCR'+str(i))
        val = Entry(frabcr,textvariable=bcrr[i])
        labl.pack()
        val.pack()
    bRead = Button(framebut, text = 'Read', command = lambda: readALREG(alc.BCR))
    bRead.pack()
    bLoad = Button(framebut, text = 'Load', command = lambda: loadALREG(alc.BCR))
    bLoad.pack()

#    var.set(1)
#    oclose()

# ECCR Menu
    tECCR = Label(fraeccr, text='End of Column Conf. Registers', font='Helvetica 14 bold')
    tECCR.pack()
    for i in range(alc.ECCRregs):
        labl = Label(fraeccr,text='ECCR'+str(i))
        val = Entry(fraeccr,textvariable=eccr[i])
        labl.pack()
        val.pack()
    bRead2 = Button(framebE, text = 'Read', command = lambda: readALREG(alc.ECCR))
    bRead2.pack()
    bLoad2 = Button(framebE, text = 'Load', command = lambda: loadALREG(alc.ECCR))
    bLoad2.pack()
    bNoRawMode = Button(framebE, text ='Disable RAW mode', command = lambda: rawMode(0))
    bNoRawMode.pack()
    bRawMode = Button(framebE, text ='Enable RAW mode', command = lambda: rawMode(1))
    bRawMode.pack()
    
# Pixel Menu
    tPCR = Label(frapcr, text='Pixel Conf. Registers', font='Helvetica 14 bold')
    tPCR.pack()
    for i in range(alc.PCRregs):
        labl = Label(frapcr,text='PCR'+str(i))
        val = Entry(frapcr,textvariable=pcrr[i])
        labl.pack()
        val.pack()
    labc = Label(frapcr,text='Channel #: ')
    valc = Entry(frapcr,textvariable=chTarget)
    labc.pack()
    valc.pack()
    bRead3 = Button(framebP, text = 'Read', command = lambda: readALREG(alc.PCR))
    bRead3.pack()
    bLoad3 = Button(framebP, text = 'Load', command = lambda: loadALREG(alc.PCR))
    bLoad3.pack()


    
def checkMenu():
    global checkt
    global cmenu
    if checkt==False:
        chipMenu()
        checkt = True
    elif checkt==True:
        closew()
        chipMenu()

but1 = Button(frame, text='Open Chip', command= checkMenu)
frame.pack()
but1.pack()
root.mainloop()
