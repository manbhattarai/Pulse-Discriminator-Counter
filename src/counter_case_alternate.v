`include "bin_gen_alternate.v"
module counter_case_alternate
    #(parameter BIN_COUNTER_WIDTH = 12,
    parameter PULSE_COUNTER_WIDTH = 8)
    (input clk,
    input dac_clk,
    input rst_n,
    input yag,
    input pulse,
    input [BIN_COUNTER_WIDTH-1:0] mem_addr, 
    output [PULSE_COUNTER_WIDTH-1:0] mem_value,
    input [BIN_COUNTER_WIDTH-1:0] mem_addr_dac, 
    output [PULSE_COUNTER_WIDTH-1:0] mem_value_dac,
    output reg yag_out_dac
);

//initialize the bin_clock
wire bin_clk;
bin_gen_alternate bin_gen_inst (
    .clk(clk),
    .rst(rst_n),
    .bin_out(bin_clk)
);
    
  
reg prev_pulse;

(* ASYNC_REG = "TRUE" *) reg [BIN_COUNTER_WIDTH-1:0] bin_counter = 0;
reg [PULSE_COUNTER_WIDTH-1:0] pulse_counter[0:2**BIN_COUNTER_WIDTH-1]; // A ram for data transfer to PS
reg [PULSE_COUNTER_WIDTH-1:0] pulse_counter_dac[0:2**BIN_COUNTER_WIDTH-1]; // A ram for data transfer to DAC
reg [PULSE_COUNTER_WIDTH-1:0] temp_counter;



reg yag_pipe_counter;
reg yag_out_counter;
always @(posedge clk)
begin
    yag_pipe_counter <= yag;
    yag_out_counter <= yag_pipe_counter;
end

/*
reg bin_clk;
always @(posedge clk)
begin
    bin_clk <= bin_clk_pipe;
end
*/

wire chip_enable;
reg count_state = 1'b1;
assign chip_enable = yag_out_counter&& count_state; // consider outting a register here


reg prev_bin_clk;
reg pulse_sync;

always @(posedge clk)
    begin
        prev_bin_clk <= bin_clk;
        prev_pulse <= pulse;

        if (!chip_enable)
        begin
            bin_counter <= 0;
            temp_counter <= 0;
            if(!yag_out_counter)
                count_state<=1;
        end
        else
        begin
            //check for eddge of bin clock
            if (bin_clk && !prev_bin_clk) // rising edge of bin clock
            begin
                bin_counter <= bin_counter + 1;
                temp_counter <= 0;
            end
            else
            begin
                bin_counter <= bin_counter;
            end

            if (pulse && !prev_pulse) // rising edge of pulse
                temp_counter <= temp_counter + 1;
            //else
            //    temp_counter <= temp_counter;

            if (bin_counter > 3_001)
                count_state <= 0;
            else
                count_state <= 1;
        end
    end
    
reg [PULSE_COUNTER_WIDTH-1:0] mem_value_reg;

assign mem_value = mem_value_reg;

always @(posedge clk)
    begin
        if (yag_out_counter) // or consider putting chip enable here
            begin
                pulse_counter[bin_counter] <= temp_counter;
                pulse_counter_dac[bin_counter] <= temp_counter;
                mem_value_reg <= 8'hFF;
            end
        else
            mem_value_reg <= pulse_counter[mem_addr];
    end


//2 FF synchronizer. Yag has crossed clock domain
reg yag_pipe_dac;
always @(posedge dac_clk)
begin
    yag_pipe_dac <= yag;
    yag_out_dac <= yag_pipe_dac;
end

reg [PULSE_COUNTER_WIDTH-1:0] mem_value_reg_dac;
assign mem_value_dac = mem_value_reg_dac;
always @(posedge dac_clk)
    begin
        if (yag_out_dac) // or consider putting chip enable here
            begin
                //pulse_counter_dac[bin_counter] <= temp_counter;
                mem_value_reg_dac <= 8'hFF;
            end
        else
            mem_value_reg_dac <= pulse_counter_dac[mem_addr_dac];
    end
    
endmodule