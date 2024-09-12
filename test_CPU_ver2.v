`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module test_cpu;
	reg reset;
	reg clk;
	wire[31:0]instruction_output_stage_1;
    wire[31:0]ALU_result_output_stage_3;
    wire[31:0]Write_data_output_stage_4;
    wire[31:0]Write_data_output_stage_5;
	wire[31:0]RF_data1;wire[31:0]RF_data2;wire[31:0]RF_data3;
	wire[31:0]RF_data4;wire[31:0]RF_data5;wire[31:0]RF_data6;
	wire[31:0]RF_data7;wire[31:0]RF_data8;wire[31:0]RF_data9;
	wire[31:0]RF_data10;wire[31:0]RF_data11;wire[31:0]RF_data12;
	wire[31:0]RF_data13;wire[31:0]RF_data14;wire[31:0]RF_data15;
	wire[31:0]RF_data16;wire[31:0]RF_data17;wire[31:0]RF_data18;
	wire[31:0]RF_data19;wire[31:0]RF_data20;wire[31:0]RF_data21;
	wire[31:0]RF_data22;wire[31:0]RF_data23;wire[31:0]RF_data24;
	wire[31:0]RF_data25;wire[31:0]RF_data26;wire[31:0]RF_data27;
	wire[31:0]RF_data28;wire[31:0]RF_data29;wire[31:0]RF_data30;
	wire[31:0]RF_data31;wire[31:0]RF_data0; 
	CPU cpu1(reset, clk,instruction_output_stage_1,ALU_result_output_stage_3,Write_data_output_stage_4,Write_data_output_stage_5,RF_data0,RF_data1,RF_data2,RF_data3,RF_data4,RF_data5,RF_data6,RF_data7,RF_data8,RF_data9,RF_data10,RF_data11,RF_data12,RF_data13,RF_data14,RF_data15,
RF_data16,RF_data17,RF_data18,RF_data19,RF_data20,RF_data21,RF_data22,RF_data23,RF_data24,RF_data25,RF_data26,RF_data27,RF_data28,RF_data29,RF_data30,RF_data31);
	initial begin
	    reset = 0;
		#5 reset = 1;clk = 1;
		#5 reset = 0;
	end
	
	always #15 clk = ~clk;
		
endmodule
