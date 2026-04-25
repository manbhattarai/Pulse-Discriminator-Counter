module adc_clk_gen(
    input adc_clk_p,
    input adc_clk_n,    
    output adc_clk 
); 

wire adc_clk_single;

IBUFGDS adc_clk_inst0 (.I(adc_clk_p), .IB(adc_clk_n), .O(adc_clk_single));
BUFG adc_clk_inst (.I(adc_clk_single), .O(adc_clk));

endmodule
