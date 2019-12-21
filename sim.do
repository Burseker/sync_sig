transcript off

# restart -force -nobreakpoint -nolist -nolog -nowave -noassertions

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L stratixii -L rtl_work -L work -voptargs="+acc" sync_sig_tb
do wave.do
view structure
view signals

run 1 us
