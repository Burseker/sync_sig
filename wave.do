onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB_GROUP /sync_sig_tb/aclr
add wave -noupdate -group TB_GROUP /sync_sig_tb/clk
add wave -noupdate -group TB_GROUP /sync_sig_tb/clka
add wave -noupdate -group TB_GROUP /sync_sig_tb/clkb
add wave -noupdate -group TB_GROUP /sync_sig_tb/clkc
add wave -noupdate -group TB_GROUP /sync_sig_tb/ureal_time
add wave -noupdate -group TB_GROUP /sync_sig_tb/real_time
add wave -noupdate -group TB_GROUP /sync_sig_tb/sync
add wave -noupdate -group TB_GROUP /sync_sig_tb/s_sync0_stb
add wave -noupdate -group TB_GROUP /sync_sig_tb/s_sync0_cnt
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate /sync_sig_tb/clk
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/clk2x
add wave -noupdate /sync_sig_tb/sync
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/clk
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/clk2x
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/isync_h
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/isync_l
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_osync
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_flag_freq_sh
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_fscale
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_ttrig_s
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_ttrig_s_r
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_dl_fs0
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_dl_st0
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate /sync_sig_tb/clk
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/clk2x
add wave -noupdate /sync_sig_tb/sync
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -expand /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_det_phase
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_stat
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stat_arr
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stat_lock
add wave -noupdate -divider <NULL>
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_det_cnt
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_det_stb
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_osync
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -expand /sync_sig_tb/sync_sig_uut/sync_handler/s_stat_arr
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stat_lock
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_flag_lock
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stA_pres
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stB_pres
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stC_pres
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_stD_pres
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_det_cnt
add wave -noupdate /sync_sig_tb/sync_sig_uut/sync_handler/s_sync_det_stb
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
add wave -noupdate -divider -height 60 <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {730000 ps} 0} {{Cursor 2} {780000 ps} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {652174 ps} {874186 ps}
