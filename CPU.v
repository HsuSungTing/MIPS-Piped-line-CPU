//seq
module InstructionMemory(Address, Instruction); //我先用他的
	input [31:0] Address;
	output reg [31:0] Instruction;//這邊感覺應該寫成RF會更像memory，這邊是用comb來模擬
	always @(*)
		case (Address)
		//I: {op	rs	rt	immediate}
		//R: {op	rs	rt	rd	shamt	funct}
			32'd0:     Instruction <= {6'd8,5'd0,5'd8, 16'd60};//I type: addi $s0, $zero, 60  |s0=60|
			32'd4:     Instruction <= {6'd0,5'd8,5'd10,5'd9, 5'd0,6'd32}; //R type: add $s1, $s0, &s2 |s1=260|
			32'd8:     Instruction <= {6'd0,5'd8, 5'd9,5'd14,5'd0,6'd32};//R type: add $s6, $s1, s0   |s6=320|
			32'd12:    Instruction <= {6'd8,5'd0,5'd15, 16'd85};//I type: addi $s7, $zero, 85   |s7=85|
			32'd16:    Instruction <= {6'd0,5'd14,5'd15, 5'd10,5'd0,6'd34};//R type: sub $s2, $s6, $s7  |s2=235|
			//32'd16:    Instruction <= {6'd4,5'd11,5'd12, 16'd0};//I type: beq $s4, $s3, 3  
			32'd20:    Instruction <= {6'd0,5'd8, 5'd10,5'd14,5'd0,6'd32};//R type: add $s6, $s2,s0  | s6=295
			32'd24:    Instruction <= {6'd35,5'd8,5'd11,16'd70};//I type: lw $s3,.70(s0)  |s3=5|
			32'd28:    Instruction <= {6'd43,5'd11,5'd10,16'd50};//I type: sw $s2,.50(s3) |將235寫入addr(5)|
			//會有一個stall
			32'd32:    Instruction <= {6'd0,5'd9,5'd10,5'd12,5'd0,6'd42};//R type: slt $s4, $s1, $s2    |s4=0|
			32'd36:    Instruction <= {6'd8,5'd0,5'd11, 16'd60};//I type: beq $s4, s2, 1  |s4=0|
			32'd40:    Instruction <= {6'd4,5'd0,5'd12, 16'd1}; //I type: beq $s4, $zero, 1  |s4=0|
			32'd44:    Instruction <= {6'd0,5'd10,5'd11,5'd13,5'd0,6'd36}; //R type: and  $s5, $s2, $s3 |s5=1但這行不會被執行|
			32'd48:    Instruction <= {6'd0,5'd13,5'd10,5'd8, 5'd0,6'd32}; //R type: add $s0, $s5, $s2  |s0=435|
			32'd52:    Instruction <= {6'd43,5'd12,5'd8,16'd20}; //I type: sw $s0,.20(s4) |將435寫入addr(20)|
			32'd56:    Instruction <= {6'd8,5'd0,5'd11, 16'd72};//I type: addi $s2, $s6, 72
			32'd60:    Instruction <= {6'd35,5'd12,5'd14,16'd20};//I type: lw $s6,.20(s4) |將435寫入addr(20)| s6=435
			32'd64:    Instruction <= {6'd0,5'd11,5'd14,5'd14,5'd0,6'd37};//R type: or  $s6, $s6, $s3  s6=507 
			32'd68:    Instruction <= {6'd8,5'd14,5'd8, 16'd72};//I type: addi $s0, $s6, 72  s0=579
			32'd72:    Instruction <= {6'd43,5'd12,5'd8,16'd20}; //I type: sw $s0,.20(s4) |將435寫入addr(20)|
			32'd76:    Instruction <= {6'd35,5'd12,5'd13,16'd20};//I type: lw $s5,.20(s4) |將435寫入addr(20)| 寫了馬上讀我不確定讀不讀的到
			32'd80:    Instruction <= {6'd2,26'd1};//J type: j 5(address=20)
			32'd84:    Instruction <= {6'd0,5'd11,5'd12,5'd14,5'd0,6'd37};//R type: or  $s6, $s4, $s3
			default: Instruction <= 32'h00000000;
		endcase
endmodule

//seq
module RegisterFile(Reset, clk, RegWrite, Read_register1, Read_register2, Write_register, Write_data,Write_enable, Read_data1, Read_data2);
	input Reset,clk,Write_enable;
	input RegWrite;
    input [4:0] Read_register1, Read_register2, Write_register;
    input [31:0]Write_data;
    output [31:0]Read_data1, Read_data2;
	reg [31:0] RF_data[31:0];
	//I: {op	rs	rt	immediate}
	//instruction: stall {6'd16,5'd1,5'd1,16'd0} 所有寫入的動作都要否定，阿ALU繼續計算沒問題
	//他沒有write enable，如果同時寫和讀應該會出事，所以我這邊用助教的寫法
	//RF到底初始化
	integer i;
	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			for (i = 0; i < 32; i = i + 1)begin
				if(i==0)RF_data[i] <= 32'd0;
				else RF_data[i] <= 32'd200;
			end
		end
		else if(Write_enable==1'b1&&RegWrite==1'b1)RF_data[Write_register]<=Write_data;//其實沒有所有情況都涵蓋
		else begin
			for (i = 0; i < 32; i = i + 1)RF_data[i] <= RF_data[i]; //這邊這樣寫OK嗎?
		end
	end
	assign Read_data1 = (Read_register1 == 5'b00000)? 32'h00000000: RF_data[Read_register1];
	assign Read_data2 = (Read_register2 == 5'b00000)? 32'h00000000: RF_data[Read_register2];
endmodule

//基本上就是RAM，主要是長期資料會回存在這裡，要用lw才能把資料讀出來，sw寫回，lw要記得把某個資料存在哪裡
module DataMemory(Reset, clk, Address, Write_data, Read_data,MemtoReg, MemWrite);
    parameter RAM_SIZE = 256;
	parameter RAM_SIZE_BIT = 8;
	input Reset, clk,MemtoReg, MemWrite;//先不放memread，無條件Read
	input [31:0]Address,Write_data;//read和write都是用同個address
	output [31:0]Read_data;
	wire [7:0]true_Address;
	assign true_Address=Address[7:0];
	reg [31:0] RAM_data[RAM_SIZE - 1: 0];
	integer i;
	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			for (i = 0; i < RAM_SIZE; i = i + 1)RAM_data[i] <= 32'd5;
		end
		else if(MemWrite==1'b1)RAM_data[true_Address]<=Write_data;//其實沒有所有情況都涵蓋
		else begin
			for (i = 0; i < RAM_SIZE; i = i + 1)RAM_data[i] <= RAM_data[i]; //這邊這樣寫OK嗎?
		end
	end
	assign Read_data=RAM_data[true_Address];
endmodule

//comb
module Control(Ins_31_26,Jump,Branch,RegDst,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite);
	input [5:0]Ins_31_26;
	output reg Jump,Branch,RegDst,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite;
	always@(*)begin
		case (Ins_31_26)
			//0的話代表R type
			6'd0:  begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b1;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;ALUSrc=1'b0;RegWrite=1'b1;
			end
			//2的話代表j
			6'd2:  begin
				Jump=1'b1;Branch=1'b0;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;//here
				ALUSrc=1'b0;RegWrite=1'b0;
			end
			//4的話代表beq
			6'd4:  begin
				Jump=1'b0;Branch=1'b1;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;//here
				ALUSrc=1'b1;RegWrite=1'b0;
			end
			//8的話代表addi
			6'd8:begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;ALUSrc=1'b1;//要做sign extend
				RegWrite=1'b1;
			end     
			//17的話代表stall
			6'd17:begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;ALUSrc=1'b1;//要做sign extend
				RegWrite=1'b0;
			end     
			//35的話代表lw
			6'd35:begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b0;MemRead=1'b1;MemtoReg=1'b1;
				MemWrite=1'b0;ALUSrc=1'b1;RegWrite=1'b1;
			end     
			//43的話代表sw
			6'd43:begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b1;ALUSrc=1'b1;RegWrite=1'b0;
			end    
			default:begin
				Jump=1'b0;Branch=1'b0;RegDst=1'b0;MemRead=1'b0;MemtoReg=1'b0;
				MemWrite=1'b0;ALUSrc=1'b0;RegWrite=1'b0;
			end
		endcase
	end
endmodule

//comb
module ALU_and_Control(data_1,data_2,Ins_31_26,Ins_5_0,Ins_15_0,ALU_result);
	input [5:0] Ins_31_26,Ins_5_0;
	input [15:0] Ins_15_0;
	input [31:0]data_1,data_2;
	output reg [31:0] ALU_result;

	always@(*)begin
		if(Ins_31_26==6'd0)begin //R type
			if(Ins_5_0==6'd32)begin //add $s1, $s0, $zero
				ALU_result=data_1+data_2;
			end
			else if(Ins_5_0==6'd34)begin //R type: sub $s2, $s1, $s0
				ALU_result=data_1-data_2;
			end
			else if(Ins_5_0==6'd36)begin
				ALU_result=data_1 & data_2;
			end
			else if(Ins_5_0==6'd37)begin //R type: or  $s6, $s4, $s3
				ALU_result=data_1 | data_2;
			end
			else if(Ins_5_0==6'd42)begin //R type: slt $s4, $s1, $s2
				if(data_1>=data_2)ALU_result=32'd0;
				else ALU_result=32'd1;
			end
			else begin
				ALU_result=32'd0;
			end
		end
		else if(Ins_31_26==6'd2)begin //beq 
			ALU_result=32'd0;
		end
		else if(Ins_31_26==6'd4)begin //beq 
			ALU_result=data_1-data_2;
		end
		else if(Ins_31_26==6'd8)begin //addi $s0, $zero, 100 
			ALU_result=data_1+{16'd0,Ins_15_0};
		end
		else if(Ins_31_26==6'd17)begin//stall  
			ALU_result=32'd3;
		end
		else if(Ins_31_26==6'd35)begin//lw
			ALU_result=data_1+{16'd0,Ins_15_0};
		end
		else if(Ins_31_26==6'd43)begin//sw
			ALU_result=data_1+{16'd0,Ins_15_0};
		end
		else begin
			ALU_result=32'd0;
		end
	end
endmodule

module IF_ID_Reg(clk,Instruction_in,Instruction_out,load_use_bool);
	input clk,load_use_bool;
	input [31:0]Instruction_in;
	output reg[31:0]Instruction_out;
	always@(posedge clk)begin
		if(load_use_bool==1'b1)Instruction_out<={6'd17,5'd1,5'd1, 16'd0};
		else Instruction_out<=Instruction_in;
	end
endmodule

module ID_EXE_Reg(clk,Read_data1_in,Read_data2_in,Read_data1_out,Read_data2_out,
MemRead_in,MemtoReg_in,MemWrite_in,RegWrite_in,Write_register_in,MemRead_out,MemtoReg_out,MemWrite_out,
RegWrite_out,Write_register_out,instruction_ver2,instruction_ver3,Read_register1_in,Read_register2_in,Read_register1_out,Read_register2_out);
	input clk,MemRead_in,MemtoReg_in,MemWrite_in,RegWrite_in;
	input [4:0]Write_register_in,Read_register1_in,Read_register2_in;
	input [31:0]Read_data1_in,Read_data2_in,instruction_ver2;

	output reg [31:0]Read_data1_out,Read_data2_out,instruction_ver3;
	output reg[4:0]Write_register_out,Read_register1_out,Read_register2_out;
	output reg MemRead_out,MemtoReg_out,MemWrite_out,RegWrite_out;

	always@(posedge clk)begin
		MemRead_out<=MemRead_in;Write_register_out<=Write_register_in;
		MemtoReg_out<=MemtoReg_in;MemWrite_out<=MemWrite_in;
		Read_data1_out<=Read_data1_in;Read_data2_out<=Read_data2_in;
		instruction_ver3<=instruction_ver2;RegWrite_out<=RegWrite_in;
		Read_register1_out<=Read_register1_in;Read_register2_out<=Read_register2_in;
	end
endmodule

module EXE_MEM(Reset,clk,
Address_in,Write_data_RAM_in,MemWrite_in,RegWrite_in,Write_register_in,MemtoReg_in,
Address_out,Write_data_RAM_out,MemWrite_out,RegWrite_out,Write_register_out,MemtoReg_out,
Ins_31_26_in,Ins_31_26_out);

	input Reset,clk,MemWrite_in,RegWrite_in,MemtoReg_in;
	input [31:0]Address_in,Write_data_RAM_in;
	input [4:0]Write_register_in;
	input [5:0]Ins_31_26_in;

	output reg MemWrite_out,RegWrite_out,MemtoReg_out;
	output reg [31:0]Address_out,Write_data_RAM_out;
	output reg [4:0]Write_register_out;
	output reg [5:0]Ins_31_26_out;
	
	reg [9:0]test_ct;
	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			test_ct<=10'd0;
		end
		else begin
			test_ct<=test_ct+10'd1;
		end
	end

	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			MemWrite_out<=1'b0;RegWrite_out<=1'b0;MemtoReg_out<=1'b0;
			Address_out<=32'd0;Write_data_RAM_out<=32'd0;
			Write_register_out<=5'd0;Ins_31_26_out<=6'd0;
		end
		else if(test_ct<10'd2)begin
			MemWrite_out<=1'b0;RegWrite_out<=1'b0;MemtoReg_out<=1'b0;
			Address_out<=32'd0;Write_data_RAM_out<=32'd0;
			Write_register_out<=5'd0;Ins_31_26_out<=6'd0;
		end
		else begin
			MemWrite_out<=MemWrite_in;RegWrite_out<=RegWrite_in;MemtoReg_out<=MemtoReg_in;
			Address_out<=Address_in;Write_data_RAM_out<=Write_data_RAM_in;
			Write_register_out<=Write_register_in;Ins_31_26_out<=Ins_31_26_in;
		end
	end
endmodule

module MEM_WB(Reset,clk,RegWrite_2,RegWrite_3,Write_data_in,Write_data_out,Write_register_in,Write_register_out,
Ins_31_26_out,Ins_31_26_in);
	input RegWrite_2,clk,Reset;
	input [31:0] Write_data_in;
	input [4:0]Write_register_in;
	input [5:0]Ins_31_26_in;
	output reg RegWrite_3;
	output reg [31:0] Write_data_out;
	output reg [4:0]Write_register_out;
	output reg [5:0]Ins_31_26_out;
	
	reg [9:0]test_ct;

	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			test_ct<=10'd0;
		end
		else begin
			test_ct<=test_ct+10'd1;
		end
	end

	always@(posedge Reset,posedge clk)begin
		if(Reset)begin
			Write_data_out<=32'd0;RegWrite_3<=1'b0;Write_register_out<=5'd0;Ins_31_26_out<=6'd0;
		end
		else if(test_ct<10'd3)begin
			Write_data_out<=32'd0;RegWrite_3<=1'b0;Write_register_out<=5'd0;//強制歸零的部分
			Ins_31_26_out<=6'd0;
		end
		else begin
			Write_data_out<=Write_data_in;RegWrite_3<=RegWrite_2;
			Write_register_out<=Write_register_in;Ins_31_26_out<=Ins_31_26_in;
		end
	end
endmodule

module CPU(Reset, clk);
	input Reset, clk;
	reg [31:0]pc;
	reg [4:0]Read_register1_ver1,Read_register2_ver1;
	reg [4:0] Write_register_1;
	wire [4:0]Write_register_2,Write_register_3,Write_register_4;
	reg [31:0]cur_Insctructions_ver1;
	wire [31:0]cur_Insctructions_ver0,cur_Insctructions_ver2,cur_Insctructions_ver3;
	wire [5:0]Ins_31_26_stage2;
	wire Jump_1,Branch_1,RegDst_1,MemRead_1,MemtoReg_1,MemWrite_1,RegWrite_1;
	reg stall_detect;

//stage 1 PC sequential logic
	reg load_use_harzard;
	reg [31:0]next_pc;
	always@(posedge Reset,posedge clk)begin
		if(Reset)pc<=32'd0;
		else if(load_use_harzard==1'b1)pc<=pc;
		else pc<=next_pc;
	end
	assign Ins_31_26_stage2=cur_Insctructions_ver2[31:26];
	InstructionMemory U1(.Address(pc),.Instruction(cur_Insctructions_ver0));
	//--------IF_ID input Instruction, output: Instruction--------
	
	always@(*)begin
		if(cur_Insctructions_ver2[31:26]==6'd35&&cur_Insctructions_ver2[20:16]==cur_Insctructions_ver1[25:21])load_use_harzard=1'b1;
		else if(cur_Insctructions_ver2[31:26]==6'd35&&cur_Insctructions_ver2[20:16]==cur_Insctructions_ver1[20:16])load_use_harzard=1'b1;
		else load_use_harzard=1'b0;
	end
	IF_ID_Reg U5(.clk(clk),.Instruction_in(cur_Insctructions_ver1),.Instruction_out(cur_Insctructions_ver2),.load_use_bool(load_use_harzard));
	//----------------------------------------------------------------------------
	
//stage 2 instruction-> Control logic+RF+Jump&branch detection(為了stall)
//如果當前instruction為lw且下一個instruction會造成harzard，pc就暫時不動且下個指令是stall
	always@(*)begin
		if(stall_detect==1'b1)cur_Insctructions_ver1={6'd17,5'd1,5'd1, 16'd0};
		else cur_Insctructions_ver1=cur_Insctructions_ver0;
	end
    reg ALUSrc_1;
	//.Ins_31_26(Ins_31_26)用ver2
	Control U0(.Ins_31_26(Ins_31_26_stage2),.Jump(Jump_1),.Branch(Branch_1),.RegDst(RegDst_1),.MemRead(MemRead_1),.MemtoReg(MemtoReg_1),.MemWrite(MemWrite_1),.ALUSrc(ALUSrc_1),.RegWrite(RegWrite_1));
	//cur_Insctructions mapping到Read_register1,Read_register2,Write_register;缺writ_edata------------------
	always@(*)begin
		Read_register1_ver1=cur_Insctructions_ver2[25:21];//rs
		Read_register2_ver1=cur_Insctructions_ver2[20:16];//rt
		if(RegDst_1==1'b0)Write_register_1=cur_Insctructions_ver2[20:16];//I type
		else Write_register_1=cur_Insctructions_ver2[15:11];           //R type
	end
	//-----------------------------------------------------------------------------------
	wire RegWrite_2,RegWrite_3,RegWrite_4;
	reg [31:0]Write_data_1,Write_data_2;
	wire [31:0]Write_data_3;
	reg [31:0]Read_data1_1,Read_data2_1;
	wire [31:0]Read_data1_2,Read_data2_2;
	wire MemRead_2,MemtoReg_2,MemWrite_2,RegDst_2;
	wire [17:0]branch_offset;
	wire [31:0]jump_offset;
	assign branch_offset={cur_Insctructions_ver2[15:0],2'd0};//offset 要乘以4
	assign jump_offset={4'd0,cur_Insctructions_ver2[25:0],2'd0};
	
	reg [31:0]Read_data1_1_for_beq,Read_data2_1_for_beq;
	wire [31:0]ALU_result_out;
	reg Write_Back_Harzard_1,Write_Back_Harzard_2;
	wire [31:0]Read_data1_1_from_RF,Read_data2_1_from_RF;
	//---beq的forward logic(因為beq提前到satge 2判斷所以要額外處理)----------
	always@(*)begin
		if(Branch_1 == 1'b1&&Write_register_3==Read_register1_ver1)begin Read_data1_1_for_beq=ALU_result_out; end
		else if(Branch_1 == 1'b1&&Write_register_4==Read_register1_ver1)begin Read_data1_1_for_beq=Write_data_3; end
		else begin Read_data1_1_for_beq=Read_data1_1_from_RF; end//如果beq這邊沒有harzard就直接用從RF讀出來的值即可
	end

	always@(*)begin
		if(Branch_1 == 1'b1&&Write_register_3==Read_register2_ver1)begin Read_data2_1_for_beq=ALU_result_out; end
		else if(Branch_1 == 1'b1&&Write_register_4==Read_register2_ver1)begin Read_data2_1_for_beq=Write_data_3; end
		else begin Read_data2_1_for_beq=Read_data2_1_from_RF;end
	end
	//------stall detect logic------------
	always@(*)begin
		if((Branch_1 == 1'b1 && Read_data1_1_for_beq == Read_data2_1_for_beq)||(Jump_1==1'b1)) stall_detect=1'b1;
		else stall_detect=1'b0;
	end
	always@(*)begin
		if(Branch_1==1'b1&&Read_data1_1_for_beq==Read_data2_1_for_beq)next_pc=pc+{14'd0,branch_offset};
		else if(Jump_1==1'b1)next_pc=jump_offset;
		else next_pc=pc+32'd4;
	end
	//----------------------------------------

	//處理Write Back Harzard
	//Read_data1_1和Read_data2_1是已經考慮過Write Back Harzard後的正確結果
	always@(*)begin
		if(Read_register1_ver1==Write_register_4&&RegWrite_4==1'b1)begin Read_data1_1=Write_data_3;Write_Back_Harzard_1=1'b1;end//還來不及寫入(差一個clk)馬上就被讀取，這邊才是最新的
		else begin Read_data1_1=Read_data1_1_from_RF; Write_Back_Harzard_1=1'b0;end//沒問題
	end
	always@(*)begin
		if(Read_register2_ver1==Write_register_4&&RegWrite_4==1'b1)begin Read_data2_1=Write_data_3; Write_Back_Harzard_2=1'b1;end//還來不及寫入(差一個clk)馬上就被讀取，這邊才是最新的
		else begin Read_data2_1=Read_data2_1_from_RF; Write_Back_Harzard_2=1'b0;end//沒問題
	end

	RegisterFile U2(.Reset(Reset),.clk(clk),.RegWrite(RegWrite_4),.Read_register1(Read_register1_ver1),.Read_register2(Read_register2_ver1),.Write_register(Write_register_4),.Write_data(Write_data_3),.Write_enable(1'b1),.Read_data1(Read_data1_1_from_RF),.Read_data2(Read_data2_1_from_RF));
	//這一段會加入Harzard detection，為了避免branch or jump 後要flush前兩個Instruction，所以這個logic會去盡早更新pc
	//ID_EXE input&output Control的所有輸出(包含ALU所需、Data_RAM所需、write_back所需),read_data_1,read_data_2,
	wire [4:0]Read_register1_ver2,Read_register2_ver2;

	ID_EXE_Reg U7(.clk(clk),.Read_data1_in(Read_data1_1),.Read_data2_in(Read_data2_1),.Read_data1_out(Read_data1_2),.Read_data2_out(Read_data2_2),
	.MemRead_in(MemRead_1),.MemtoReg_in(MemtoReg_1),.MemWrite_in(MemWrite_1),.RegWrite_in(RegWrite_1),.Write_register_in(Write_register_1),
	.MemRead_out(MemRead_2),.MemtoReg_out(MemtoReg_2),.MemWrite_out(MemWrite_2),.RegWrite_out(RegWrite_2),.Write_register_out(Write_register_2),
	.instruction_ver2(cur_Insctructions_ver2),.instruction_ver3(cur_Insctructions_ver3),.Read_register1_in(Read_register1_ver1),.Read_register2_in(Read_register2_ver1),
	.Read_register1_out(Read_register1_ver2),.Read_register2_out(Read_register2_ver2));
	//以及為了forward unit(為了解決EXE or MEM data Harzard)要多傳read_reg_1,read_reg_2

//stage 3 ALU_and_Control
	wire [5:0]Ins_5_0;
	wire [5:0]Ins_31_26_stage3;
	wire [5:0]Ins_31_26_stage4,Ins_31_26_stage5;
	assign Ins_5_0=cur_Insctructions_ver3[5:0];//這邊先試試看
	assign Ins_31_26_stage3=cur_Insctructions_ver3[31:26];
	wire [15:0]Ins_15_0;
	assign Ins_15_0=cur_Insctructions_ver3[15:0];
	wire [31:0]ALU_result;//ALU_result是stage 3的ALU_result
	//這邊的Ins_31_26(Ins_31_26),.Ins_5_0(Ins_5_0),.Ins_15_0(Ins_15_0)應該要用第三版cur_instruction
	
	wire [31:0]Read_data2_3;//ALU_result_out是stage 4的ALU_result
	wire MemWrite_3,MemtoReg_3;
	reg [1:0]forward_bool_1,forward_bool_2;
	reg [31:0]Read_data1_2_after_forward,Read_data2_2_after_forward;

	//Forward Logic
	//我這邊好聰明，直接用Write_register3和4代替掉有rd or rt(I type和R type要寫回的register不同)
	always@(*)begin
		if(Write_register_3==Read_register1_ver2&&Ins_31_26_stage4!=6'd2&&Ins_31_26_stage4!=6'd4&&Ins_31_26_stage4!=6'd43)begin Read_data1_2_after_forward=ALU_result_out; forward_bool_1=2'd1;end
		else if(Write_register_4==Read_register1_ver2&&Ins_31_26_stage5!=6'd2&&Ins_31_26_stage5!=6'd4&&Ins_31_26_stage5!=6'd43)begin Read_data1_2_after_forward=Write_data_3; forward_bool_1=2'd2;end
		else begin Read_data1_2_after_forward=Read_data1_2; forward_bool_1=2'd0;end
	end

	always@(*)begin
		if(Write_register_3==Read_register2_ver2&&Ins_31_26_stage4!=6'd2&&Ins_31_26_stage4!=6'd4&&Ins_31_26_stage4!=6'd43)begin Read_data2_2_after_forward=ALU_result_out; forward_bool_2=2'd1;end
		else if(Write_register_4==Read_register2_ver2&&Ins_31_26_stage5!=6'd2&&Ins_31_26_stage5!=6'd4&&Ins_31_26_stage5!=6'd43)begin Read_data1_2_after_forward=Write_data_3; forward_bool_2=2'd2;end
		else begin Read_data2_2_after_forward=Read_data2_2; forward_bool_2=2'd0;end
	end
	
	ALU_and_Control U3(.data_1(Read_data1_2_after_forward),.data_2(Read_data2_2_after_forward),.Ins_31_26(Ins_31_26_stage3),.Ins_5_0(Ins_5_0),.Ins_15_0(Ins_15_0),.ALU_result(ALU_result));
	//這一段會加入forward unit(為了解決EXE or MEM data Harzard)
	//EXE_MEM input&output Control的所有輸出(包含Data_RAM所需、write_back所需)，以及D_RAM要用的address和write_data
	EXE_MEM U9(.Reset(Reset),.clk(clk),.Address_in(ALU_result),.Write_data_RAM_in(Read_data2_2_after_forward),.MemWrite_in(MemWrite_2),.RegWrite_in(RegWrite_2),.Write_register_in(Write_register_2),.MemtoReg_in(MemtoReg_2),
	.Address_out(ALU_result_out),.Write_data_RAM_out(Read_data2_3),.MemWrite_out(MemWrite_3),.RegWrite_out(RegWrite_3),.Write_register_out(Write_register_3),.MemtoReg_out(MemtoReg_3),.Ins_31_26_in(Ins_31_26_stage3),.Ins_31_26_out(Ins_31_26_stage4));

//stage 4 write back logic(要把RegWrite_3,Write_register_3,Write_data_2傳回stage 2的RF中)
	//MEM_WB會等兩個clk(如果有在多插入就是三個)後根據Reg_write_2決定是否要寫入，在此之前都是Reg_write_3都是0
	wire [31:0]Read_data_from_ram;

	DataMemory U4(.Reset(Reset),.clk(clk),.Address(ALU_result_out),.Write_data(Read_data2_3),.Read_data(Read_data_from_ram),.MemtoReg(MemtoReg_3),.MemWrite(MemWrite_3));
	always@(*)begin
		if(MemtoReg_3==1'b1)Write_data_2=Read_data_from_ram;
		else Write_data_2=ALU_result_out;   //直接寫進register
	end
	
	MEM_WB U8(.Reset(Reset),.clk(clk),.RegWrite_2(RegWrite_3),.RegWrite_3(RegWrite_4),.Write_data_in(Write_data_2),.Write_data_out(Write_data_3),.Write_register_in(Write_register_3),.Write_register_out(Write_register_4),.Ins_31_26_in(Ins_31_26_stage4),.Ins_31_26_out(Ins_31_26_stage5));
endmodule
