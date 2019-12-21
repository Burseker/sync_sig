module one_bit_delay (aclr,clk,clk_en,in,out);

parameter LENGTH=8192;

input	  aclr;
input	  clk_en;
input	  clk;
input	  in;
output	  out;

wire taps;

localparam	lpm_hint = "RAM_BLOCK_TYPE=M4K";
localparam	lpm_type = "altshift_taps";
localparam	number_of_taps = 1;
localparam	tap_distance = LENGTH;
localparam	width = 1;


altshift_taps	#(.lpm_hint(lpm_hint),
                .lpm_type(lpm_type),
                .number_of_taps(number_of_taps),
                .tap_distance(tap_distance),
                .width(width)
                ) 
    altshift_taps_component
                (.clken (clk_en),
				.aclr (aclr),
				.clock (clk),
				.shiftin (in),
				.taps (taps),
				.shiftout (out)
                );
	
	// localparam	altshift_taps_component.lpm_hint = "RAM_BLOCK_TYPE=M512",
	// localparam	altshift_taps_component.lpm_type = "altshift_taps",
	// localparam	altshift_taps_component.number_of_taps = 1,
	// localparam	altshift_taps_component.tap_distance = LENGTH,
	// localparam	altshift_taps_component.width = 1;


endmodule


