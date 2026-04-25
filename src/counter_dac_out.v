module counter_dac_out
    #(parameter BIN_COUNTER_WIDTH = 12,
    parameter PULSE_COUNTER_WIDTH = 8,
    parameter DAC_DATA_WIDTH  = 14)
    (input dac_clk,
    input rst_n,
    input yag_out_dac,
    input ddr_clk,
    input pll_locked,
    
    input [PULSE_COUNTER_WIDTH-1:0] mem_value,
    output dac_clk_o,dac_wrt_o,dac_sel_o,dac_rst_o,
    output [BIN_COUNTER_WIDTH-1:0] mem_addr,
    output [13:0] dac_dat_o    
    );
    

reg [BIN_COUNTER_WIDTH-1:0] mem_addr_temp;
reg [13:0] dac_out_temp;
reg [13:0] dac_out;

always @(posedge dac_clk)
begin
    dac_out_temp <= {6'b0,mem_value}<<8; //scaling up the data to be sent to dac. Could be set as an input variable.
    dac_out <= {dac_out_temp[DAC_DATA_WIDTH-1], ~dac_out_temp[DAC_DATA_WIDTH-2:0]};
end

assign mem_addr = mem_addr_temp;


always @(posedge dac_clk)
begin
    if(!rst_n)
    begin
        mem_addr_temp <= 0;
    end
    else
    begin
        if (yag_out_dac)
            mem_addr_temp <= 0;
        else
        begin
            if(mem_addr_temp < 3001)
                mem_addr_temp <= mem_addr_temp + 1;
            else
                mem_addr_temp <= 3002;
        end
        
    end
end

reg  dac_rst;
always @(posedge dac_clk)
    dac_rst <= ~pll_locked;


ODDR ODDR_rst              (.Q(dac_rst_o), .D1(dac_rst), .D2(dac_rst), .C(  dac_clk  ), .CE(1'b1), .R( 1'b0  ), .S(1'b0)); 
ODDR ODDR_sel              (.Q(dac_sel_o), .D1( 1'b0  ), .D2( 1'b1  ), .C(  dac_clk  ), .CE(1'b1), .R(1'b0), .S(1'b0)); 
ODDR ODDR_wrt              (.Q(dac_wrt_o), .D1( 1'b0  ), .D2( 1'b1  ), .C(ddr_clk), .CE(1'b1), .R( 1'b0  ), .S(1'b0));
ODDR ODDR_clk              (.Q(dac_clk_o), .D1( 1'b0  ), .D2( 1'b1  ), .C(ddr_clk), .CE(1'b1), .R( 1'b0  ), .S(1'b0));

genvar j;
generate
    for(j = 0; j < DAC_DATA_WIDTH; j = j + 1)
    begin : DAC_DAT
      ODDR ODDR_inst(
        .Q(dac_dat_o[j]),
        .D1(dac_out[j]),
        .D2(dac_out[j]),
        .C(dac_clk),
        .CE(1'b1),
        .R(1'b0),
        .S(1'b0)
      );
    end
  endgenerate

        
    
endmodule
