transcript on
vmap altera C:/WrkPrFiles/modeltech_10.2c/ALTERA/vhdl_libs/altera
vmap lpm C:/WrkPrFiles/modeltech_10.2c/ALTERA/vhdl_libs/lpm
vmap sgate C:/WrkPrFiles/modeltech_10.2c/ALTERA/vhdl_libs/sgate
vmap altera_mf C:/WrkPrFiles/modeltech_10.2c/ALTERA/vhdl_libs/altera_mf
vmap stratixii C:/WrkPrFiles/modeltech_10.2c/ALTERA/vhdl_libs/stratixii
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {./src/_atoms/ram_dp_v1.vhd}
vcom -93 -work work {./src/_atoms/del_line_v21.vhd}
vcom -93 -work work {./src/_atoms/pwr_on.vhd}
vcom -93 -work work {./src/_atoms/pkg_func.vhd}
vcom -93 -work work {./src/_atoms/pkg_sim.vhd}
vcom -93 -work work {./src/_atoms/bidir.vhd}
vcom -93 -work work {./src/_atoms/param_mux.vhd}
vcom -93 -work work {./src/_atoms/packer_arp/packerx1/muxN_1_r.vhd}
vcom -93 -work work {./src/_atoms/packer_arp/packerx1/addr_frmr_x1.vhd}
vcom -93 -work work {./src/_atoms/del_line_v3.vhd}
vcom -93 -work work {./src/_atoms/crc16_iw32.vhd}
vcom -93 -work work {./src/_atoms/crc16_iw16.vhd}
vcom -93 -work work {./src/_atoms/crc16_iw8.vhd}
vcom -93 -work work {./src/_atoms/cnt_genchk.vhd}
vcom -93 -work work {./src/_atoms/rnd_genchk.vhd}
vcom -93 -work work {./src/_atoms/stb_cdc_v2.vhd}
vcom -93 -work work {./src/_atoms/mcp_cdc.vhd}
vcom -93 -work work {./src/_atoms/mul_cplx_v2.vhd}
vcom -93 -work work {./src/_atoms/shift_rounder_47_to_16.vhd}
vcom -93 -work work {./src/_atoms/zero_one_check.vhd}

vcom -93 -work work {./src/sync_handler/sync_handler.vhd}

vcom -93 -work work {./src/sync_sig_top.vhd}
vcom -93 -work work {./src/sync_sig_tb.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L stratixii -L rtl_work -L work -voptargs="+acc" sync_sig_tb

do sim.do
