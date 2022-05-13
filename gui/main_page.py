#! /usr/bin/env python3
#
#   Import packages
import tkinter
from tkinter import ttk
from tkinter import messagebox
import os
#
#   Main Window
main_window = tkinter.Tk()
main_window.title("ALCOR@BO GUI")
main_window.geometry('1000x500')
tab_controller = ttk.Notebook(main_window)
#
#   Overview tab
Toverview      = ttk.Frame(tab_controller)
tab_controller.add  ( Toverview,     text='Overview' )
#
#   Enable Execute system
bEnableExecute = tkinter.BooleanVar()
bEnableExecute.set(False)
C_Enable = tkinter.Checkbutton( Toverview, text='Enable commands', var=bEnableExecute )
C_Enable.grid( column=0, row=0 )
#
#   General execute command function
def uExecuteCommand ( cmd ):
    if bEnableExecute.get():
        bEnableExecute.set(False)
        return os.system(cmd)
    print(cmd)
    return 1
#
#   Setting Temperature for Memmert
L_Memmert_Set = ttk.Label( Toverview, text='Set Memmert Temp:' )
L_Memmert_Set.grid( column=0, row=1 )
E_Memmert_Set = ttk.Entry( Toverview, width=5 )
E_Memmert_Set.grid( column=1, row=1 )
L_Memmert_OK = ttk.Label( Toverview, foreground='green', text='OK!' )
L_Memmert_NO = ttk.Label( Toverview, foreground='red', text='NOT SET!' )
#
# Set Memmert Temp
def uSetMemmertTemp( ):
    #if ( int(E_Memmert_Set.get()) < -50 ) or ( int(E_Memmert_Set.get()) > 200 ):
    #    messagebox.showerror( title='Invalid Temperature', message='Temperature should be a value from -40C to +200C' )
    cmd = '/au/memmert/set --temp ' + E_Memmert_Set.get()
    rsp = uExecuteCommand(cmd)
    if not rsp:
        L_Memmert_OK.grid(column=3, row=1)
    else:
        L_Memmert_NO.grid(column=3, row=1)
#    
Bmemmerttempset = ttk.Button( Toverview, text="Apply", command=uSetMemmertTemp )
Bmemmerttempset.grid(column=2, row=1)
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
Tivscan   = ttk.Frame(tab_controller)
tab_controller.add  ( Tivscan,  text='IV Scan' )
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
tab_controller.pack ( expand=1,      fill='both'  )
#
main_window.mainloop()
#
# TODO: function to add buttons quickly w/ name and ON/OFF YES/NO with commands in input
