proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/Pipelined_Processor_tb/clk
}

vlib work

;# Compile components if any
vcom Pipelined_Processor.vhd
vcom Pipelined_Processor_tb.vhd
vcom Fetch.vhd
vcom Instruction_Memory.vhd
vcom Decode.vhd
vcom Execute.vhd
vcom Memory.vhd
vcom Data_Memory.vhd
vcom Write_Back.vhd
vcom RegisterBlock.vhd

;# Start simulation
vsim Pipelined_Processor_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 ns
run 10000ns