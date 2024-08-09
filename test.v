`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module test_cpu;
	reg reset;
	reg clk;
	CPU cpu1(reset, clk);
	initial begin
	    reset = 0;
		#5 reset = 1;clk = 1;
		#5 reset = 0;
	end
	
	always #15 clk = ~clk;
		
endmodule
