module myfifo #(parameter FIFO_DEPTH = 1<<11,
                parameter COUNTER_SIZE = 12,
                parameter ADC_DATA_WIDTH = 14)
(
    input clk_in,
    input clk_out,
    input rst_n_in,
    input rst_n_out,
    input enable_fifo_in,
    
    input [13:0] data_in,
    output reg full_reg,
    output reg empty_reg,
    output [13:0] data_out
);

//reg full_reg;
//reg empty_reg;
reg [ADC_DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
reg [ADC_DATA_WIDTH-1:0] data_out_reg;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_in;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_out;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_in_pipe;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_in_pipe2;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_out_pipe;
(* ASYNC_REG = "TRUE" *) reg [COUNTER_SIZE-1:0] counter_out_pipe2;


//convert gray to binary with a look up table loaded a a ROM
reg [COUNTER_SIZE-1:0] gray2bin [0:2**COUNTER_SIZE-1];
reg [COUNTER_SIZE-1:0] bin2gray [0:2**COUNTER_SIZE-1];
initial
begin
    $readmemb("gray2bin.mem", gray2bin,0,2**COUNTER_SIZE-1);
    $readmemb("bin2gray.mem", bin2gray,0,2**COUNTER_SIZE-1);
end


reg [COUNTER_SIZE-1:0] counter_in_next;
//assign counter_in_next = counter_in + 1;
reg [COUNTER_SIZE-1:0] counter_out_next;
//assign counter_out_next = counter_out + 1;


always@(posedge clk_in)
begin
    if (!rst_n_in) begin
        counter_in <= 0;
        counter_in_next <= 1;
        counter_out_pipe <= 0;
        counter_out_pipe2 <= 0;
        full_reg <=0;
    end else begin
            counter_out_pipe <= bin2gray[counter_out]; //change counter_out  to gray
            counter_out_pipe2 <= counter_out_pipe;
            //full_reg <= (counter_in_next[COUNTER_SIZE-2:0]  == gray2bin[counter_out_pipe2[COUNTER_SIZE-2:0]]) && 
            //                                                                                                (counter_in_next[COUNTER_SIZE-1] != gray2bin[counter_out_pipe2[COUNTER_SIZE-1]]);  
                                                                                                            
            full_reg <= (counter_in_next[COUNTER_SIZE-2:0]  == gray2bin[counter_out_pipe2][COUNTER_SIZE-2:0]) && 
                                                                                                            (counter_in_next[COUNTER_SIZE-1] != counter_out_pipe2[COUNTER_SIZE-1]);                                                                                                 
            if(enable_fifo_in) begin
                if(~full_reg) begin
                    fifo[counter_in[COUNTER_SIZE-2:0]] <= data_in;
                    counter_in <= counter_in + 1;
                    counter_in_next <= counter_in_next + 1;
                end
            end
    end
end

always@(posedge clk_out)
begin
    if (!rst_n_out) begin
        counter_out <= 0;
        counter_out_next <= 1;
        counter_in_pipe <= 0;
        counter_in_pipe2 <= 0;
        empty_reg <= 1;
    end
    else 
    begin
        counter_in_pipe <= bin2gray[counter_in]; //change counter_in to gray
        counter_in_pipe2 <= counter_in_pipe;
        if(~empty_reg) 
        begin
            data_out_reg <= fifo[counter_out[COUNTER_SIZE-2:0]];
            counter_out <= counter_out + 1;
            counter_out_next <= counter_out_next + 1;
            empty_reg <= (counter_out_next == gray2bin[counter_in_pipe2]); 
        end
        else
        begin
            empty_reg <= (counter_out == gray2bin[counter_in_pipe2]); 
        end
        
    end
end

assign data_out = data_out_reg;

endmodule