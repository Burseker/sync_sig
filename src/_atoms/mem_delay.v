module mem_delay (aclr,clk,clk_en,in_data,out_data,out_stb);

parameter WIDTH=16;
parameter DEL_LENGTH=10;	
parameter COUNT_SIZE=4;

input aclr,clk,clk_en;
input [WIDTH-1:0] in_data;
output [WIDTH-1:0] out_data;
output reg out_stb;
//assign out_stb = 
genvar i;

generate for(i=0; i<WIDTH;i=i+1) begin :d_line
	 one_bit_delay #(DEL_LENGTH) altshift_taps_inst (	aclr,
													clk,
													clk_en,
													in_data[i],
													out_data[i]);
end endgenerate

reg [COUNT_SIZE-1:0] r_counter;
reg r_counter_en;
always @(posedge clk, posedge aclr)
begin
    if(aclr)begin
        r_counter <= 0;
        r_counter_en <= 1;
    end
    else begin
        if(clk_en)begin
            if(r_counter == DEL_LENGTH-2)begin
                r_counter_en <= 0;
                //r_counter    <= DEL_LENGTH-2;
            end
            else begin
            
                r_counter_en <= 1;
                
                if(r_counter_en)begin
                    r_counter <= r_counter + {{{COUNT_SIZE-1}{1'b0}},{1'b1}};
                end
            end
        end
    end
end

always @(posedge clk, posedge aclr)
begin
    if(aclr)begin
        out_stb <= 0;
    end
    else begin
        out_stb <= clk_en & (~r_counter_en);
    end
end

endmodule
