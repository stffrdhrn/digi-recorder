# This doesnt really work, but I want to figure out how to do it
# so putting these helpers here.  
vsim:
	vlog bench/dacspi_tb.v
	vlog rtl/dacspi.v
	vsim -c -do "run; quit" dacspi_tb

vlib: work
	vlib work
