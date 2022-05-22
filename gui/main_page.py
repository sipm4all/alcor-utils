#! /usr/bin/env python3
#
#   Import packages
import tkinter
from tkinter import ttk
from tkinter import messagebox
import subprocess
import os
#
#   --- --- --- --- --- --- ---
#   --- --- --- --- MAIN SETTINGS AND ALL TABS
#   --- --- --- --- --- --- ---
#
#   Main Window
main_window = tkinter.Tk()
main_window.title("ALCOR@BO GUI")
main_window.geometry('1000x500')
tab_controller = ttk.Notebook(main_window)
#
#   2022 characterisation scan tab
T2022scan      = ttk.Frame(tab_controller)
tab_controller.add  ( T2022scan,     text='2022 scan' )
#
#   Overview tab
Toverview      = ttk.Frame(tab_controller)
tab_controller.add  ( Toverview,     text='Overview' )
#
#   IV Scan tab
Tivscan   = ttk.Frame(tab_controller)
tab_controller.add  ( Tivscan,  text='IV Scan' )
#
#   Memmert Tab
Tmemmert   = ttk.Frame(tab_controller)
tab_controller.add  ( Tmemmert,  text='Memmert' )
#
#   Enable Execute system
bEnableExecute = tkinter.BooleanVar()
bEnableExecute.set(False)
C_Enable_Overview   = tkinter.Checkbutton   ( Toverview,    text="Enable",  var=bEnableExecute )
C_Enable_IVScan     = tkinter.Checkbutton   ( Tivscan,      text="Enable",  var=bEnableExecute )
C_Enable_2022Scan   = tkinter.Checkbutton   ( T2022scan,    text="Enable",  var=bEnableExecute )
C_Enable_Memmert    = tkinter.Checkbutton   ( Tmemmert,     text="Enable",  var=bEnableExecute )
B_Quit_Overview     = tkinter.Button        ( Toverview,    text="Quit",    command=main_window.destroy)
B_Quit_IVScan       = tkinter.Button        ( Tivscan,      text="Quit",    command=main_window.destroy)
B_Quit_2022Scan     = tkinter.Button        ( T2022scan,    text="Quit",    command=main_window.destroy)
B_Quit_Memmert      = tkinter.Button        ( Tmemmert,     text="Quit",    command=main_window.destroy)
C_Enable_Overview   .grid( column=0, row=0 )
C_Enable_IVScan     .grid( column=0, row=0 )
C_Enable_2022Scan   .grid( column=0, row=0 )
C_Enable_Memmert    .grid( column=0, row=0 )
B_Quit_Overview     .grid( column=1, row=0 )
B_Quit_IVScan       .grid( column=1, row=0 )
B_Quit_2022Scan     .grid( column=1, row=0 )
B_Quit_Memmert      .grid( column=1, row=0 )
#
#   General execute command function
def uExecuteCommand ( cmd ):
    if bEnableExecute.get():
        bEnableExecute.set(False)
        return os.system(cmd)
    print('command execution not enabled: ', cmd)
    return 1
#
#   --- --- --- --- --- --- ---
#   --- --- --- --- 2022 SCAN TAB
#   --- --- --- --- --- --- ---
#
L_2022Scan1_Set = ttk.Label( T2022scan, text='Status of board:' )
L_2022Scan1_Set.grid( column=0, row=1 )
E_2022Scan1_Set = ttk.Entry( T2022scan, width=5 )
E_2022Scan1_Set.grid( column=1, row=1 )
#
L_2022Scan2_Set = ttk.Label( T2022scan, text='# of setup:' )
L_2022Scan2_Set.grid( column=0, row=2 )
E_2022Scan2_Set = ttk.Entry( T2022scan, width=5 )
E_2022Scan2_Set.grid( column=1, row=2 )
#
def uStart2022Scan ( ):
    cmd = '/au/measure/2022-characterisation/start.sh ' + str(E_2022Scan1_Set.get()) + ' ' + str(E_2022Scan2_Set.get())
    rsp = os.system(cmd)
    return 1
#
def uStop2022Scan ( ):
    cmd = '/au/measure/2022-characterisation/kill.sh'
    rsp = uExecuteCommand(cmd)
    return 1
#
def uStatus2022Scan ( ):
    cmd = '/au/measure/2022-characterisation/status.sh'
    rsp = os.system(cmd)
    return 1
#
B_2022Scan_start = ttk.Button( T2022scan, text="START", command=uStart2022Scan )
B_2022Scan_start.grid(column=0, row=3)
#
B_2022Scan_start = ttk.Button( T2022scan, text="STATUS", command=uStatus2022Scan )
B_2022Scan_start.grid(column=1, row=3)
#
B_2022Scan_start = ttk.Button( T2022scan, text="KILL", command=uStop2022Scan )
B_2022Scan_start.grid(column=2, row=3)
#
# HV ON/OFF
L_HV_onoff = ttk.Label( Toverview, text='Set HV status:' )
L_HV_onoff.grid( column=0, row=2 )
def uSetHV( status ):
    cmd = '' 
    if status:
        cmd = '/au/tti/hv.on'
    else:
        cmd = '/au/tti/hv.off'
    rsp = uExecuteCommand(cmd)
def uSetHVon():
    uSetHV(True)
def uSetHVoff():
    uSetHV(False)
B_HV_on = ttk.Button( Toverview, text="ON", command=uSetHVon )
B_HV_on.grid(column=1, row=2)
B_HV_off = ttk.Button( Toverview, text="OFF", command=uSetHVoff )
B_HV_off.grid(column=2, row=2)
#
#                                                                                                                          
# Temperature memmert SET                                                                                                   
L_Bologna_scan = ttk.Label( Toverview, text='Start Bologna Scan' )
L_Bologna_scan.grid( column=0, row=3 )
E_Bologna_scan = ttk.Entry( Toverview, width=25 )
E_Bologna_scan.grid( column=1, row=3 )
#                                                                                                                           
# Start Bologna Scan
def uStartBaselineScan( ):
    cmd = '/au/measure/2022-characterisation/run-baseline-calibration.sh ' + str(E_Bologna_scan.get())
    rsp = uExecuteCommand(cmd)
#                                                                                                                           
B_Bologna_scan = ttk.Button( Toverview, text="Apply", command=uStartBaselineScan )
B_Bologna_scan.grid(column=2, row=3)
#
#   IV Scan panel
L_Campaign = ttk.Label( Tivscan, text='Campaign:' )
L_Campaign.grid( column=0, row=1 )
E_Campaign = ttk.Entry( Tivscan, width=50 )
E_Campaign.grid( column=1, row=1, columnspan = 2 )
L_Runname = ttk.Label( Tivscan, text='Run name:' )
L_Runname.grid( column=0, row=2 )
E_Runname = ttk.Entry( Tivscan, width=50 )
E_Runname.grid( column=1, row=2, columnspan = 2 )
L_Runname = ttk.Label( Tivscan, text='MUX1:' )
L_Runname.grid( column=0, row=4 )
L_Runname = ttk.Label( Tivscan, text='MUX2:' )
L_Runname.grid( column=0, row=5 )
L_Runname = ttk.Label( Tivscan, text='NAME:' )
L_Runname.grid( column=1, row=3 )
L_Runname = ttk.Label( Tivscan, text='Serial:' )
L_Runname.grid( column=2, row=3 )
#
def test_make_script ( ):
    L_Runname = ttk.Label( Tivscan, text='Serial:' )
    L_Runname.grid( column=6, row=6 )
#
#   --- --- --- --- --- --- ---
#   --- --- --- --- MEMMERT TAB
#   --- --- --- --- --- --- ---
#
#   --- --- Check Memmert Temp
def uCheckMemmert2h():
   top= tkinter.Toplevel(main_window)
   top.geometry("800x380")
   top.title("Memmert 2h")
   I_CheckMemmert_2h_STD= tkinter.PhotoImage(file='/home/eic/DATA/memmert/PNG/draw_memmert_2h.png')
   I_CheckMemmert_2h    = I_CheckMemmert_2h_STD.subsample(2,2)
   panel = ttk.Label( top, image = I_CheckMemmert_2h)
   panel.I_CheckMemmert_2h = I_CheckMemmert_2h
   panel.grid( column=0, row=0 )
def uCheckMemmert8h():
   top= tkinter.Toplevel(main_window)
   top.geometry("800x380")
   top.title("Memmert 2h")
   I_CheckMemmert_2h_STD= tkinter.PhotoImage(file='/home/eic/DATA/memmert/PNG/draw_memmert_8h.png')
   I_CheckMemmert_2h    = I_CheckMemmert_2h_STD.subsample(2,2)
   panel = ttk.Label( top, image = I_CheckMemmert_2h)
   panel.I_CheckMemmert_2h = I_CheckMemmert_2h
   panel.grid( column=0, row=0 )
def uCheckMemmert24h():
   top= tkinter.Toplevel(main_window)
   top.geometry("800x380")
   top.title("Memmert 2h")
   I_CheckMemmert_2h_STD= tkinter.PhotoImage(file='/home/eic/DATA/memmert/PNG/draw_memmert_24h.png')
   I_CheckMemmert_2h    = I_CheckMemmert_2h_STD.subsample(2,2)
   panel = ttk.Label( top, image = I_CheckMemmert_2h)
   panel.I_CheckMemmert_2h = I_CheckMemmert_2h
   panel.grid( column=0, row=0 )
def uCheckMemmert1w():
   top= tkinter.Toplevel(main_window)
   top.geometry("800x380")
   top.title("Memmert 2h")
   I_CheckMemmert_2h_STD= tkinter.PhotoImage(file='/home/eic/DATA/memmert/PNG/draw_memmert_1w.png')
   I_CheckMemmert_2h    = I_CheckMemmert_2h_STD.subsample(2,2)
   panel = ttk.Label( top, image = I_CheckMemmert_2h)
   panel.I_CheckMemmert_2h = I_CheckMemmert_2h
   panel.grid( column=0, row=0 )
#
#   --- --- Buttons to check Memmert
B_CheckMemmert_2h   = ttk.Button( Tmemmert, text='Check 2h', command=uCheckMemmert2h  )
B_CheckMemmert_2h.grid( column=0, row=1 )
B_CheckMemmert_8h   = ttk.Button( Tmemmert, text='Check 8h', command=uCheckMemmert8h  )
B_CheckMemmert_8h.grid( column=1, row=1 )
B_CheckMemmert_24h   = ttk.Button( Tmemmert, text='Check 24h', command=uCheckMemmert24h  )
B_CheckMemmert_24h.grid( column=2, row=1 )
B_CheckMemmert_1w   = ttk.Button( Tmemmert, text='Check 1w', command=uCheckMemmert1w  )
B_CheckMemmert_1w.grid( column=3, row=1 )
#
#   --- --- Set Memmert Temp
L_Memmert_OK = ttk.Label( Tmemmert, foreground='green', text='Success!' )
L_Memmert_NO = ttk.Label( Tmemmert, foreground='red', text='Error!' )
def uSetMemmertTemp( ):
    cmd = '/au/memmert/set --temp ' + E_Memmert_Set.get()
    rsp = uExecuteCommand(cmd)
    if not rsp:
        L_Memmert_OK.grid(column=3, row=2)
    else:
        L_Memmert_NO.grid(column=3, row=2)
def uGetMemmertTemp( ):
    result = subprocess.run(['/au/memmert/get','--temp'], stdout=subprocess.PIPE)
    temp_1 = (str(result).split(': '))[1]
    temp_2 = (temp_1.split('\\'))[0]
    bGetMemmertT.set(temp_2)
    main_window.after(2000, uGetMemmertTemp)
def uGetMemmertRH( ):
    result = subprocess.run(['/au/memmert/get','--rh'], stdout=subprocess.PIPE)
    temp_1 = (str(result).split(': '))[1]
    temp_2 = (temp_1.split('\\'))[0]
    bGetMemmertRH.set(temp_2)
    main_window.after(2000, uGetMemmertRH)
#
#   --- --- Entry to set Temperature for Memmert
L_Memmert_Set = ttk.Label( Tmemmert, text='Set Temp:' )
L_Memmert_Set.grid( column=0, row=2 )
E_Memmert_Set = ttk.Entry( Tmemmert, width=5 )
E_Memmert_Set.grid( column=1, row=2 )
Bmemmerttempset = ttk.Button( Tmemmert, text="Apply", command=uSetMemmertTemp )
Bmemmerttempset.grid(column=2, row=2)
#
#   --- --- Read Temperature / RH
bGetMemmertT    = tkinter.StringVar()
bGetMemmertRH   = tkinter.StringVar()
L_Memmert_Get   = ttk.Label( Tmemmert, text='Temperature:' )
L_Memmert_Get.grid( column=0, row=3 )
E_Memmert_Get   = ttk.Entry( Tmemmert, width=5, state='disabled', text=bGetMemmertT, foreground='black' )
E_Memmert_Get.grid( column=1, row=3 )
L_Memmert_Get   = ttk.Label( Tmemmert, text='Humidity:' )
L_Memmert_Get.grid( column=2, row=3 )
E_Memmert_Get   = ttk.Entry( Tmemmert, width=5, state='disabled', text=bGetMemmertRH, foreground='black' )
E_Memmert_Get.grid( column=3, row=3 )
uGetMemmertTemp()
uGetMemmertRH()
#
tab_controller.pack ( expand=1,      fill='both'  )
#
main_window.mainloop()
#
# TODO: function to add buttons quickly w/ name and ON/OFF YES/NO with commands in input

