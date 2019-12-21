onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sync_sig_tb/aclr
add wave -noupdate /sync_sig_tb/clk
add wave -noupdate /sync_sig_tb/clka
add wave -noupdate /sync_sig_tb/clkb
add wave -noupdate /sync_sig_tb/clkc
add wave -noupdate /sync_sig_tb/ureal_time
add wave -noupdate /sync_sig_tb/real_time
add wave -noupdate /sync_sig_tb/sync
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {944668 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 189
configure wave -valuecolwidth 168
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1050 ns}
