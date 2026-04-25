
module bin_gen_alternate
    #(parameter COUNT_WIDTH = 12)
   (input clk,
    input rst,
    output bin_out
    );
        
    reg bin_clk_A=1'b0;
    
    reg [COUNT_WIDTH-1:0] countA; 
    
    //The clock is running at 250 MHz. 
    //A bin pulse of width 2(PHASE_OFFSET) clock cycles is produced with repetition rate of 10 us (= 2500/250 MHz). 
    reg [COUNT_WIDTH-1:0] COUNT = 12'd1249;  //COUNT = f_clk/(2*f_div)-1
    
    assign bin_out = bin_clk_A;
    
    always @(posedge clk)
    begin
        if (!rst)
            begin
                countA <= 0;
                bin_clk_A <= 1'b0;
            end
        else
            begin
                if (countA < COUNT)
                    countA <= countA + 1;
                else
                    begin
                        bin_clk_A <= ~bin_clk_A;
                        countA <= 0;
                    end
            end
    end
    

            
endmodule
