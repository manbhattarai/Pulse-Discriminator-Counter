module adc_interface(
    input [13:0] adc_dat_a,
    input adc_clk,
    //output [7:0] led
    output adc_csn,
    output reg [13:0] adc_data_out    
 ); 

assign adc_csn = 1;

reg [13:0]adc_data_in;
always@(posedge adc_clk)
begin
    adc_data_out <= adc_dat_a;
end

//Convert the adc data to gray code before sending to discriminator where clock domain crossing occurs.
/*
wire [13:0]adc_data_gray;
assign adc_data_gray = (adc_data_in>>1)^adc_data_in;

always@(posedge adc_clk)
begin
    adc_data_out <= adc_data_gray;
end
*/

endmodule