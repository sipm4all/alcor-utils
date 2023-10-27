#
# Python main interface to ALCOR firmware and registers.
# This file must match registers specified in connection.xml file
# mapping KC705 resources
#
# @P. Antonioli/D. Falchieri - 2021
#
#
#
import os
import ipbus
import spi
import time

verbose = 0

nRETRY = 0

### R+SPEED: allow for setup of a single channel
oneChannel = False
theChannel = 0

SETREG  = 1
RDREG   = 0


BCR             = 1
ECCR            = 2
PCR             = 4
DIRECTREG       = 10
ECSR            = 17
SSR             = 12
lanes           = 4
channels        = 32

## BCR Registers
BCRregs  = 8
# BCR_0246 = 0x1
# iTDC field [6:2] is recommended at 320 MHz
BCR_0246 = 0x3D
BCR_1357 = 0xCBFD ## R+: this should be 0xC9FD

test_pulse_cal=0 ## ampiezza del test pulse [7 per pulse grande]
BCR_0246 = (1 << 0) | (15 << 2) | (test_pulse_cal << 7) | (0 << 10) ## R+: from F.Chiosso settings
BCR_1357 = 0xC599 ## R+: from F.Chiosso settings

polarity_select=1
bit_boost=25 #  [25 for normal, 15 for test pulse]
bit_cg=12 # [12 for normal, 29 for test pulse]
BCR_1357 = (bit_cg << 0) | (bit_boost << 5) | (polarity_select << 10) | (0 << 11) | (0 << 12) | (3 << 14)

## tags to steer set PCR2/PCR3
PCR2thr=0
PCR2off=1
PCR2ran=2
PCR3offset1=0
PCR3opmode=1
PCR3polarity=2

# ECCR Registers
ECCRregs = 4
ECCR_COL0_enable  = 0x1
ECCR_COL0_safeBit = 0x2
ECCR_COL0_Iratio  = 0x4
ECCR_COL1_enable  = 0x8
ECCR_COL1_safeBit = 0x10
ECCR_COL1_Iratio  = 0x20
ECCR_RAWMODE      = 0x800
ECCR_RAWMODE_Bit  = 11
ECCR_810b_enable  = 0x1000
ECCR_SER_enable   = 0x2000
ECCR_SER_align    = 0x4000
ECCR_STAT_enable  = 0x8000 
ECCR_default = 0x303F

ECCR_default = 0x301b ## R+: from F.Chiosso settings
#ECCR_default = ECCR_default | ECCR_RAWMODE
ECCR_default = ECCR_default | ECCR_STAT_enable

# Pixel
POLARITY_SELECT=0x2 ## -- this bit ON == positive polarity
PCRregs = 4
PCR_PIXEL  = 4
PCR_COLUMN = 8
PIXMODE = 9
PIX_OFF=0x0
PIX_LET=0x1
PIX_LET_TP_TDC=0x2
PIX_LET_TP_FE=0x3
PIX_TOT=0x4
PIX_TOT_TP_TDC=0x5
PIX_TOT_TP_FE=0x6
#PCRdefault={0:0x7777,1:0x8888,2:0xFFFF,3:PIX_OFF}
#PCRdefault={0:0x7777,1:0x8888,2:0xFFFF,3:PIX_LET|POLARITY_SELECT} ## R+: from F.Cossio configuration
PIX_MASK_DEFAULT=0x1
PIX_DEFAULT=PIX_LET

def encodeBCR0(cal,iTDC,iblatchTDC):
    data = (iblatchTDC << 0) | (iTDC << 2) | (cal << 7)
    return data

def encodeBCR1(ib_2,ib_3,ib_sF,S0,Bit_boost,Bit_cg):
    data = (Bit_cg << 0) | (Bit_boost << 5) | (S0 << 10) | (ib_sF << 11) | (ib_3 << 12) | (ib_2 << 14)
    return data

def encodePCR2(le2DAC,offset,rangeThr,threshold):
    data=((le2DAC&0x3F) << 10) | (offset&0x3) << 8 | (rangeThr&0x3) << 6 | (threshold&0x3F) << 0
    return data

def encodePCR3(offset1,opMode,offset2,gain1,gain2,polarity):
    data=((offset1&0x7)<<13) | (opMode&0xF)<<9 | ((offset2&0x7) << 6) | (gain1&0x3) << 4 | (gain2&0x3) << 2 | (polarity&0x1) << 1
    return data


ThrMax=0x3F 
ThrOffsetMax=0x3
ThrRangeMax=0x3
ThrDefault=ThrMax ## R+: to find from Thr scans!!!
#              LE1DAC             RANGE       OFFSET      LE2DAC
PCR2default = (ThrDefault << 0) | (3 << 6) | (0 << 8) | (ThrMax << 10) ## R+: from F.Cossio settings
PCRdefault={0:0x7777,1:0x8888,2:PCR2default,3:POLARITY_SELECT} ## R+: from F.Cossio settings
# Pixel operation mode: bits 12:9 PCR3

# Controller command fields
CONTROLLER_CODE      = 20
cmdResetDelayCtrl    = 0x01
cmdResetSerDes       = 0x02
cmdSetDelayTaps      = 0x03
cmdSetSyncResetPhase = 0x04
cmdDoReset           = 0x05
HardRESET            = 0x500001
SoftRESET            = 0x500000
cmdResetCounters     = 0x10
cmdSyncTx            = 0x11
cmdReadTxState       = 0x12
cmdRead8B10BErrCounters = 0x13
cmdStartTxWordAlign  = 0x14
cmdReadTxWordAlignResult = 0x15
cmdSetTxDataEnable    = 0x20
cmdSetTxEventFilters = 0x33
cmdList={"Reset Delay Ctrl":cmdResetDelayCtrl,"Reset SerDes":cmdResetSerDes,"Set Delay Taps":cmdSetDelayTaps,"Set Sync Reset Phase":cmdSetSyncResetPhase,"Do Reset":cmdDoReset,"Reset Counters":cmdResetCounters,"Sync TX":cmdSyncTx,"Read TX State":cmdReadTxState,"Read 8B10B Err Counters":cmdRead8B10BErrCounters,"Start TX Word Align":cmdStartTxWordAlign,"Read TX Word Align Result":cmdReadTxWordAlignResult}
cmdOptList = ["Reset Delay Ctrl","Reset SerDes","Set Delay Taps","Set Sync Reset Phase","Do Reset","Reset Counters","Sync TX","Read TX State","Read 8B10B Err Counters","Start TX Word Align","Read TX Word Align Result"]


### Register naming / chip dependent   *** must match address_table ***
ctrlRegList={0:"alcor_controller_id0",1:"alcor_controller_id1",2:"alcor_controller_id2",3:"alcor_controller_id3",4:"alcor_controller_id4",5:"alcor_controller_id5"}
fifoRegList={0:"alcor_readout_id0",1:"alcor_readout_id1",2:"alcor_readout_id2",3:"alcor_readout_id3",4:"alcor_readout_id4",5:"alcor_readout_id5"}
spiRegList={0:"spi_id0",1:"spi_id1",2:"spi_id2",3:"spi_id3",4:"spi_id4",5:"spi_id5"}
pulserRegList={0:"testpulse_id0",1:"testpulse_id1",2:"testpulse_id2",3:"testpulse_id3",4:"testpulse_id4",5:"testpulse_id5"}

# Miscellanea
actWrd={RDREG:'Expected',SETREG:'Setting'}
regType={BCR:"Bias Conf.",ECCR:"EoC Conf.",PCR:"Pixel Conf.",ECSR:"EoC Status",SSR:"SPI Status"}
regNr={BCR:BCRregs,ECCR:ECCRregs,PCR:PCRregs}

def set_bit(value, bit):
    return value | (1<<bit)

def clear_bit(value, bit):
    return value & ~(1<<bit)

def PIXOP(data):
    return (data<<PIXMODE)

def programPtrReg(hw,chip,type,add,data,flag):
    """Write/Read a PTR Alcor register, return value set"""
    spiPtr=(spi.PTR(type)|add)
    ipstat=spi.execCmd(hw,chip,spi.WPTR,spiPtr)  # set the pointer
    if flag==SETREG:
        ipstat=spi.execCmd(hw,chip,spi.WDAT,data) # write data in the register
    ipstat=spi.execCmd(hw,chip,spi.RDAT,0)       # read it back
    return ipstat&0xFFFF

def readMode(hw):
    ipstat=ipbus.read(hw,"regfile.mode")
    return ipstat

def setMode(hw,data):
    ipstat=ipbus.write(hw,"regfile.mode",data)
    return ipstat

def ctrl(hw,chip,data):
    """Write on ALCOR Controller register, return value set"""
    r=ctrlRegList[chip]
    ipstat=ipbus.write(hw,r,data)
    ipstat=ipbus.read(hw,r)
#    print "CTRL ",hex(data),hex(ipstat)
    return ipstat

def encodeCtrl(code,data):
    encdata=(code<<CONTROLLER_CODE)|(data&0xFFFFF)
    return encdata

def sendCtrl(hw,chip,code,data):
    val=encodeCtrl(code,data)
    stat=ctrl(hw,chip,val)
    return stat

def data(d):
    col=((d&0xE0000000)>>29)
    pix=((d&0x1C000000)>>26)
    ch=col*4+pix
    tdc=((d&0x03000000)>>24)
    coarse=((d&0x00FFFE00)>>9)
    fine=(d&0x1FF)
    print("[",'0x%08X'%d,"] Ch#: ",ch," Column: ",col," Pix: ",pix," TDC: ",tdc, " Coarse: ",'%06d'%coarse," Fine: ",'%03d'%fine)
    return 0


def setupBCR(hw,chip,reg,d):
    if (reg == 0):
      for ad in range(0,7,2):  
        d=programPtrReg(hw,chip,BCR,ad,d,SETREG)
    else:
      for ad in range(1,8,2):  
        d=programPtrReg(hw,chip,BCR,ad,d,SETREG)

def setupECCR(hw,chip,mode):
    for ad in range(ECCRregs):
        d=mode 
        d=programPtrReg(hw,chip,ECCR,ad,d,SETREG)
    return 0

def reset(hw,chip):
    ctrl(hw,chip,HardRESET)

def resetFifo(hw,chip):
    data=0x1
#    r=fifoRegList[chip]
#    ipstat=ipbus.write(hw,r+".fifo_reset",data)
    for i in range(lanes):
        r=fifoRegList[chip]+"_lane{}.fifo_reset".format(i)
#        ipstat=ipbus.write(hw,r,data)
        ipstat=ipbus.post(hw,r,data)
    hw.dispatch()

def globalCommands(hw,chip,delay):
    ECCR_Init=(ECCR_default|ECCR_SER_align)&(~ECCR_RAWMODE)
    setupECCR(hw,chip,ECCR_Init)
    stat=sendCtrl(hw,chip,cmdResetDelayCtrl,0)
    stat=sendCtrl(hw,chip,cmdResetSerDes,0)
    dd=int(delay)
    tap=(dd<<15)|(dd<<10)|(dd<<5)|(dd<<0)
    stat=sendCtrl(hw,chip,cmdSetDelayTaps,tap)
    stat=sendCtrl(hw,chip,cmdSetSyncResetPhase,0)
    stat=sendCtrl(hw,chip,cmdDoReset,0)
    stat=sendCtrl(hw,chip,cmdResetCounters,0)
    stat=sendCtrl(hw,chip,cmdSetTxEventFilters,0xF)
    return 0

def init2(hw,chip,delay,lmask):
    status=0
    adir=os.environ.get("ALCOR_CONF")
    if (adir == None):
        print("[AlcorLib] Fatal: missing environment variable ALCOR_CONF")
        exit(1)
    else:
        print("[AlcorLib] Loading conf from ",adir)
    print(" ------------- Setup chip # ",chip," -----------------")
    ctrl(hw,chip,HardRESET)
    globalCommands(hw,chip,delay)
    enabledLanes=0
    for ad in range(lanes):
        if ( (1<<ad) & lmask):
           print(" Lane # :",ad,end=" ")
           print(" 8bit-align ",end=" ")
           ECCR_Init=(ECCR_default|ECCR_SER_align)&(~ECCR_RAWMODE)        
           d=programPtrReg(hw,chip,ECCR,ad,ECCR_Init,SETREG)
           lbit=(1<<ad)
           stat=sendCtrl(hw,chip,cmdSyncTx,lbit)
           if ( (stat & lbit) != lbit ):
              print("FAILED",flush=True)
              print("+++ [Chip # ",chip,"Failed 8 bit alignment lane ",ad,"(stat:", hex(stat))
              status=1
           else:
              print("  OK  ",end=" ")
#           stat=sendCtrl(hw,chip,cmdReadTxState,ad)
#           print("Lane # ",ad,"ReadTxState: ",hex(stat))
           print("32bit-align ",end=" ") 
           ECCR_Init=(ECCR_default)&(~ECCR_RAWMODE)
           stat=sendCtrl(hw,chip,cmdStartTxWordAlign,ad)
           d=programPtrReg(hw,chip,ECCR,ad,ECCR_Init,SETREG)
           checkAlign=True
           while (checkAlign == True):
               stat= ( sendCtrl(hw,chip,cmdReadTxWordAlignResult,ad) & 0xF )
               if ((stat&0x8) | (stat&0x1)):
                   checkAlign=False
#           print("  StartTxWordAlignResult status ",hex(stat),flush=True)
           if ( (stat & 0x1) ):
              print("FAILED",flush=True)
              print("+++ [Chip # ",chip,"Failed 32 bit alignment lane ",ad)
              status=1
           else:
              print("  OK  ",flush=True)
              enabledLanes|=(1<<ad)
           d=programPtrReg(hw,chip,ECCR,ad,ECCR_default,SETREG)

    print("Enabled lanes for readout",hex(enabledLanes))
    stat=sendCtrl(hw,chip,cmdSetTxDataEnable,enabledLanes) #R+HACK write 0xf in case
    stat=sendCtrl(hw,chip,cmdResetCounters,0)
    for ad in range(lanes):
           adA=ad*2
           adB=adA+1
           err1 = ( sendCtrl(hw,chip,cmdRead8B10BErrCounters,adA) & 0xFFFFF)
           err2 = ( sendCtrl(hw,chip,cmdRead8B10BErrCounters,adB) & 0xFFFFF)
           if ( (err1 > 0) | (err2 > 0) ):
               print("Error counters lane # ",ad,"after alignment ",err1,err2)

           
    setupECCR(hw,chip,ECCR_default)   
    resetFifo(hw,chip)
    return status

    
def init(hw,chip):
    adir=os.environ.get("ALCOR_CONF")
    if (adir == None):
        print("[AlcorLib] Fatal: missing environment variable ALCOR_CONF")
        exit(1)
    else:
        print("[AlcorLib] Loading conf from ",adir)
    ctrl(hw,chip,HardRESET)
    ECCR_Init=(ECCR_default|ECCR_SER_align)&(~ECCR_RAWMODE)
    setupECCR(hw,chip,ECCR_Init)
    status=loadSequence(hw,chip,adir+"/alcor-sync.cfg")
    ECCR_Init=ECCR_default&(~ECCR_RAWMODE)
    setupECCR(hw,chip,ECCR_Init)
    status=loadSequence(hw,chip,adir+"/alcor-align.cfg")
    if (status == 1):
        print("---- FATAL FATAL FATAL ----")
        exit(1)
    ### R+fix
    if (status == 2):
        print("---- RETRY RETRY RETRY ----")
        global nRETRY
        nRETRY = nRETRY + 1
        if nRETRY > 10:
            exit(1)
        return 1
    setupECCR(hw,chip,ECCR_default)

    resetFifo(hw,chip)

    return 0
#    data=1
#    ipstat=ipbus.write(hw,r+".fifo_reset",data)
### R+HACK -- must reset all lanes
#    for i in range(lanes):
#        r=fifoRegList[chip]+"_lane{}.fifo_reset".format(i)
#        ipstat=ipbus.write(hw,r,data)
#    ipstat=ipbus.write(hw,r+"_lane0.fifo_reset",data)
#    ipstat=ipbus.write(hw,r+"_lane1.fifo_reset",data)
#    ipstat=ipbus.write(hw,r+"_lane2.fifo_reset",data)
#    ipstat=ipbus.write(hw,r+"_lane3.fifo_reset",data)

def setBias(hw,chip,Bit_cg,Bit_boost,S0):
    d = (Bit_cg << 0) | (Bit_boost << 5) | (S0 << 10) | (0 << 11) | (0 << 12) | (3 << 14)
    for ad in (1,3,5,7):
        d=programPtrReg(hw,chip,BCR,ad,d,SETREG)

def setup(hw,chip,pixSetup,channelMask):
    for ad in range(BCRregs):
        if (ad & 0x1):
            d=BCR_1357
        else:
            d=BCR_0246
        d=programPtrReg(hw,chip,BCR,ad,d,SETREG)

    for ad in range(ECCRregs):
        d=ECCR_default
        d=programPtrReg(hw,chip,ECCR,ad,d,SETREG)

    for col in range(PCR_COLUMN):
        for pxl in range(PCR_PIXEL):
            ch = pxl + col*4
            for reg in range(PCRregs):
                ad = (col<<5)|(pxl<<2)|reg
                d  = PCRdefault[reg]
                if ( (1<<ch) & channelMask ):
                    if (reg == 3):
                        d |= PIXOP(pixSetup)  # it was PIX_ON
#                print "[ALCOR # ",chip,"] PCR Ad: ",ch,hex(col),hex(pxl),hex(reg),hex(ad),"[",actWrd[SETREG],": ",hex(d)," ",
                data=programPtrReg(hw,chip,PCR,ad,d,SETREG)
#                print "DATA Read: ",hex(data&0xFFFF),"]"
    
    return 0

def loadBCRSetup(hw,chip,BCRfile):
    print("Loading BCR file ",BCRfile,"for chip # ",chip,"....")
    loadReg=0
    with open(BCRfile) as f:
        for line in f:
            first_char=line[0]
            if first_char != "#":
                ll=' '.join(line.split())
                bcrList = ll.split(" ")
                reg=int(bcrList[0])
                loadReg+=1
                if reg & 0x1:
                    ib_2=int(bcrList[1])
                    ib_3=int(bcrList[2])
                    ib_sF=int(bcrList[3])
                    S0=int(bcrList[4])
                    Bit_boost=int(bcrList[5])
                    Bit_cg=int(bcrList[6])
                    dreg=encodeBCR1(ib_2,ib_3,ib_sF,S0,Bit_boost,Bit_cg)
                else:
                    cal=int(bcrList[1])
                    iTDC=int(bcrList[2])
                    iblatchTDC=int(bcrList[3])
                    dreg=encodeBCR0(cal,iTDC,iblatchTDC)
                data=programPtrReg(hw,chip,BCR,reg,dreg,SETREG)
    print("Loaded configuration for ",loadReg," Bias Control Registers")

def setPCR2(hw,chip,ch,field,value):
    d  = 0
    ad = ((ch&0x3C)<<3) | ((ch&0x3)<<2)|2
    data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
    if (field == PCR2thr):
        d= (data & 0xFFC0) | (value & 0x3F)
    elif (field == PCR2off):
        d= (data & 0xFF3F) | ((value&0x3)<< 8)
    elif (field == PCR2ran):
        d= (data & 0xFCFF) | ((value&0x3)<< 6)
    data=programPtrReg(hw,chip,PCR,ad,d,SETREG)

def setPCR3(hw,chip,ch,field,value):
    d  = 0
    ad = ((ch&0x3C)<<3) | ((ch&0x3)<<2)|3
    data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
    if (field == PCR3offset1):
        d= (data & 0x1FFF) | ((value & 0x7) << 13)
    elif (field == PCR3opmode):
        d= (data & 0xE1FF) | ((value&0xF)<< 9)
    elif (field == PCR3polarity):
        d= (data & 0xFFFD) | ((value&0x1)<< 1)
    data=programPtrReg(hw,chip,PCR,ad,d,SETREG)


def setPCR3Offset(hw,chip,ch,offset):
    d  = 0
    ad = ((ch&0x3C)<<3) | ((ch&0x3)<<2)|3
    data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
    d=(data & 0x1FFF)
    d=data|(offset<<13)
    data=programPtrReg(hw,chip,PCR,ad,d,SETREG)


def loadPCRSetup(hw,chip,PCRfile,mask):
    print("Loading PCR file ",PCRfile,"for chip # ",chip,"....")
    loadCh=0
    with open(PCRfile) as f:
        for line in f:
            first_char=line[0]
            if first_char != "#":
                ll=' '.join(line.split())
                pcrList = ll.split(" ")
                ch=int(pcrList[0])
                ### R+SPEED: allow for setup of a single channel
                if oneChannel and ch != theChannel:
                    continue
                loadCh+=1
                # PCR2 
                le2DAC=int(pcrList[1])
                offset=int(pcrList[2])
                rangeThr=int(pcrList[3])
                threshold=int(pcrList[4])
                # PCR3
                Offset1=int(pcrList[5])
                if ((1<<ch) & mask):
                    OpMode=int(pcrList[6])
                else:
                    OpMode=0
                Offset2=int(pcrList[7])
                Gain1=int(pcrList[8])
                Gain2=int(pcrList[9])
                Polarity=int(pcrList[10])
                #
#                print "=== channel", ch
#                print "PCR 2 components"
#                print "   le2DAC ",le2DAC
#                print "   offset ",offset
#                print "   range ",rangeThr
#                print "   threshold ",threshold
                #
#                print "PCR 3 components"
#                print "   Offset1 ",Offset1
#                print "   OpMode ",OpMode
                pcr2=encodePCR2(le2DAC,offset,rangeThr,threshold)
                pcr3=encodePCR3(Offset1,OpMode,Offset2,Gain1,Gain2,Polarity)
                ad = ((ch&0x3C)<<3) | ((ch&0x3)<<2)
                data=programPtrReg(hw,chip,PCR,ad|2,pcr2,SETREG)
                data=programPtrReg(hw,chip,PCR,ad|3,pcr3,SETREG)
#                print "Setting on ch. # ",ch,"PCR2: ",hex(pcr2),"PCR3 ",hex(pcr3)
    print("Loaded specific configuration for ",loadCh,"channels")

def setChannelMask(hw,chip,channelMask):
    for col in range(PCR_COLUMN):
        for pxl in range(PCR_PIXEL):
            ch = pxl + col*4
            ad = (col<<5)|(pxl<<2)|0x3    
            d=0
            data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
            if ( (1<<ch) & channelMask ):
                d=(data & 0xE1FF)          # we keep as it is excluding pixop
                d |= PIXOP(PIX_LET)        # we turn it on
            else:
                d=(data & 0xE1FF)          # we keep all the rest and we disable channel
            data=programPtrReg(hw,chip,PCR,ad,d,SETREG)

def cacca(hw):
    return 0

def thresholdOnly(hw,chip,thr,channelMask):
    for col in range(PCR_COLUMN):
        for pxl in range(PCR_PIXEL):
            ch = pxl + col*4
            if ( (1<<ch) & channelMask ):
                d=0
                ad = (col<<5)|(pxl<<2)|0x2    # PCR2 control threshold
                data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
                offset=(data>>8)&0x3
                rangeThr=(data>>6)&0x3
#                print "Channel ",ch,"found with PCR2 ",hex(data),offset,rangeThr
                d= (0x3F << 10) | (offset&0x3)<<8 | (rangeThr&0x3)<<6 | thr&0x3F 
#                print "Channel ",ch,"new setting ",hex(d),offset,rangeThr
                data=programPtrReg(hw,chip,PCR,ad,d,SETREG)
            else:
                d = 0
                ad = (col<<5)|(pxl<<2)|0x3    # PCR3 set channel off
                data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
                d=(data & 0xE1FF)          # we keep all the rest and we disable channel
                data=programPtrReg(hw,chip,PCR,ad,d,SETREG)
    return 0

def threshold(hw,chip,thr,rangeThr,offset,channelMask):
    for col in range(PCR_COLUMN):
        for pxl in range(PCR_PIXEL):
            ch = pxl + col*4
            if ( (1<<ch) & channelMask ):
                ad = (col<<5)|(pxl<<2)|0x2    # PCR2 control threshold
                d  = (0x3F << 10) | (offset&0x3)<<8 | (rangeThr&0x3)<<6 | thr&0x3F 
                if ( verbose == 1):
                    print("[ALCOR # ",chip,"] PCR2 Thr on ch:",ch,hex(ad),"LE1DAC:",thr," Range:",rangeThr," Offset:",offset," [",actWrd[SETREG],": ",hex(d)," ",)
                data=programPtrReg(hw,chip,PCR,ad,d,SETREG)
                if ( verbose == 1):
                    print("DATA Read: ",hex(data&0xFFFF),"]")
            else:
                d = 0
                ad = (col<<5)|(pxl<<2)|0x3    # PCR3 set channel off
                data=programPtrReg(hw,chip,PCR,ad,d,RDREG)
                d=(data & 0xE1FF)          # we keep all the rest and we disable channel
                data=programPtrReg(hw,chip,PCR,ad,d,SETREG)
    return 0

def loadSequence(hw,chip,fileToLoad):
    ### R+fix to detect lane not aligned
    stored_lane_check = 0x0
    has_stored_lane_check = False
    
    print("Loading command sequences to ALCOR controller from: ",fileToLoad)
    with open(fileToLoad,'r') as f:
        for line in f:
            ctrlWord=int(line,16)
            ctrlCmd=(ctrlWord & 0xFF00000)>>CONTROLLER_CODE
            if (verbose > 0):
                print("Sending command to ALCOR Controller # ",chip,": ",hex(ctrlWord),hex(ctrlCmd))
            ipstat=ctrl(hw,chip,ctrlWord)
            if (verbose > 0):
                print("[Read back Register =  ",hex(ipstat),"]")
            if (ctrlCmd == cmdSyncTx):
                if ( (ctrlWord & 0xF) == 0):
                    if ( (ipstat & 0xF) != 0xF ):
                        print("FATAL: ALCOR lanes not correctly synced")
                        return 1
            ### R+fix to detect lane not correctly aligned
            if ctrlCmd == cmdReadTxWordAlignResult:
                if not has_stored_lane_check:
                    stored_lane_check = ipstat
                    has_stored_lane_check = True
                elif ipstat != stored_lane_check:
                    print("FATAL: ALCOR lanes not correctly synced")
                    return 2
    return 0
