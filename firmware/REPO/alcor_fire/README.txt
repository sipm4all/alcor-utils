
Firmware for Alcor-Firefly board

	firmware revisions:
		- top_18Sept2021.bit:
				-- data filter implemented: comand 0x33 in alcor_controller, tx_buffer_filter_proc in alcor_tx_word_buffer.vhd
				-- improved the process tx_buffer_fifo_write_proc in alcor_tx_word_buffer.vhd
		- top_19Sept2021.bit:
				-- regs.status implemented with bit 0 containing the spill signal actual value in payload.vhd
				-- (triggers accepted only during spills)
		- top_19Sept2021_1.bit:
				-- modified trigger_info.vhd (trigger_info_state_machine_proc process and following ones)
				-- allowing to accept triggers also outside the spill condition
		- top_19Sept2021_2.bit:
				-- based upon top_19Sept2021.bit release (original trigger_info state machine, triggers accepted only during spills)
				-- in alcor_dataout, I added the counter_timelike 32-bit counter, which is reset when running fifo_reset
				-- and which can be read by accessing address 0x5
		- top_20Sept2021.bit:	
				-- data filter implemented: comand 0x33 in alcor_controller, tx_buffer_filter_proc in alcor_tx_word_buffer.vhd
				-- improved the process tx_buffer_fifo_write_proc in alcor_tx_word_buffer.vhd
				-- allowing to accept triggers also outside the spill condition (alternate philosophy in trigger_info.vhd)
				-- in alcor_dataout, I added the counter_timelike 32-bit counter, which is reset when running fifo_reset
				-- and which can be read by accessing address 0x5
				-- regs.status implemented with bit 0 containing the spill signal actual value in payload.vhd
		- top_20Sept2021_1.bit:
				-- changed alcor_dataout using a First Word Fall Through FIFO (instead of Standard) and changing the readout process
		- top_06Oct2021.bit:
				-- fixed a bug in alcor_dataout (counter_timelike not giving the ack when read)
				-- adding reset_fifo_proc and reset_fifo signal, which is active for 20 Ipbus clock periods
				-- fifo_data: added more accuracy bits on data count
		- top_12Oct2021.bit:
				-- built on top of top_06Oct2021.bit, with free Ethernet core
		- top_13Oct2021.bit:
				-- in trigger_info.vhd, I replaced fifo_data with fifo_data_trigger which is a standard fifo