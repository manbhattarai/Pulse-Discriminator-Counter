`include "myfifo.v"
/*
module myfifo #(parameter FIFO_DEPTH = 4096,
                parameter COUNTER_SIZE = 13,
                parameter ADC_DATA_WIDTH = 14)
(
    input clk_in,
    input clk_out,
    input rst_n_in,
    input rst_n_out,
    input enable_fifo_in,
    input [13:0] data_in,
    output [13:0] data_out
);
*/

module discriminator_FIFO
#(  parameter ADC_DATA_WIDTH = 14)
(   input adc_clk,
    input rst_n_adc,
    input [ADC_DATA_WIDTH-1:0] adc_data_in,
    input [ADC_DATA_WIDTH-1:0] threshold,
    input main_clk,
    input rst_n_main,
    input yag, //Yag clock determines when the FIFO stops reading
    input [1:0]disc_width,
    output full_reg,
    output empty_reg,
    output reg disc_out_valid,
     output threshold_met_test,
    output reg yag_out
);



//2 FF synchronizer for the external yag signal
always@(posedge main_clk)
begin
    yag_sync <= yag;
    yag_out <= yag_sync;
end

//Send data across the different clock domain using adc_clk
wire [ADC_DATA_WIDTH-1:0] adc_data_out;
myfifo fifo_init ( .clk_in(adc_clk),
                   .clk_out(main_clk),
                   .rst_n_in(rst_n_adc),
                   .rst_n_out(rst_n_main),
                   .enable_fifo_in(yag_out),
                   .data_in(adc_data_in),
                   .full_reg(full_reg),
                   .empty_reg(empty_reg),
                   .data_out(adc_data_out)
                   );


//pipeline adc data
reg [ADC_DATA_WIDTH-1:0] adc_out_piplined;
always@(posedge main_clk)
    adc_out_piplined <= adc_data_out;

// main discriminator
reg [3:0]count; // Pulse generated when the threshold is met will have a width of 2^2 clock cyccles. 
// include a way to make the width of disc_out_valid variable

reg [3:0] count_eff;
always @(*)
begin
    case(disc_width)
        2'b00 : count_eff = {3'b0, count[0]};
        2'b01 : count_eff = {2'b0, count[1:0]};
        2'b10 : count_eff = {1'b0, count[2:0]};
        2'b11 : count_eff = count;
        default: count_eff = count;
    endcase
end


reg disc_out;

reg threshold_met;
reg threshold_met_prev = 0;

assign threshold_met_test = threshold_met; // Temperory output to monitor the performance of the device. 

reg yag_sync;
always@(posedge main_clk)
begin
    threshold_met_prev <= threshold_met;
    if (adc_out_piplined > threshold)
        threshold_met <= 1;
    else
        threshold_met <=0;    
end

wire enable;

assign enable = (count_eff == 0)?1:0; //count changed to count_eff


always@(posedge main_clk)
begin
    if(threshold_met && !threshold_met_prev)
    begin
        count <=0;
        disc_out <= 1;
    end
    else
    begin
        count <= count + 1;
        disc_out <= 0;
    end
end

//register that follows the main logic
always@(posedge main_clk)
begin
    if(!rst_n_main)
        disc_out_valid <= 0;
    else
    begin
        if(enable)
            disc_out_valid <= disc_out;
    end
end


endmodule
