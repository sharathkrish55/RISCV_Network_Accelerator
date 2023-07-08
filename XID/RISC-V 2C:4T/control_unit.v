`timescale 1ns / 1ps

module control_unit(
	input [31:0] instr,
	output reg [3:0] aluop,
	output reg reg_w,
	output reg mem_w,
	output reg i_type,
	output reg [63:0] imm_val,
	output reg mem_out_wb,
  output reg [1:0] branch,
  output reg xor_acc_en
    );
	
	`define RTYPE  5'b01100
	`define ITYPE  5'b00100
	`define LOAD   5'b00000
	`define STORE  5'b01000
	`define BRANCH 5'b11000
  	`define XORACC 5'b11100

	always @(*)
	begin
      case (instr[6:2])
		`RTYPE : 
			case (instr[14:12])
				3'b000 : 
					case(instr[31:25])
						7'b0000000 : aluop = 4'h1; //ADD
						7'b0100000 : aluop = 4'h2; //SUB	
						default: aluop = 0;
					endcase
				3'b001 : aluop = 4'h6; //SLL
				3'b010 : aluop = 4'h8; //SLT
				3'b011 : aluop = 4'h9; //SLTU
				3'b100 : aluop = 4'h5; //XOR
				3'b101 : aluop = 4'h7; //SRL
				3'b110 : aluop = 4'h4; //OR
				3'b111 : aluop = 4'h3; //AND
				
				default: aluop = 0;
			endcase
		`ITYPE :
			case (instr[14:12])
					3'b000 :begin //ADDI
							aluop = 4'h1;
						end
              		3'b001 : begin //SLLI
                      		aluop = 4'h6;
                    	end
              		3'b100 : begin //XORI
                      		aluop = 4'h5;
                    	end
                    3'b101 : begin //SRLI
                      		aluop = 4'h7;
                    	end
			3'b101 : begin
				aluop = 4'h7;
				end
					default:begin
                                                        aluop = 0;
                                                end
			endcase
		`LOAD : begin
				aluop = 4'h1;
			end
		`STORE : begin
				aluop = 4'h1;
			end
		`BRANCH : begin
				case (instr[14:12])
						3'b000: aluop = 4'h5; //BEQ
						3'b001: aluop = 4'h5; //BNE
						3'b100: aluop = 4'h8; //BLT
						3'b101: aluop = 4'h8; //BGE
						default:aluop  = 4'h0;
				endcase
			  end
		default: aluop = 0;
	endcase
	end

	always @(*)
	begin
      case (instr[6:2])
		`ITYPE :
			case (instr[14:12])
					3'b000 : imm_val = {{52{instr[31]}}, instr[31:20]}; //ADDI
              		3'b001 : imm_val = {{52{instr[31]}}, instr[31:20]}; //SLLI
              		3'b101 : imm_val = {{52{instr[31]}}, instr[31:20]}; //SRLI
              		3'b100 : imm_val = {{52{instr[31]}}, instr[31:20]}; //XORI
					default: imm_val = 64'b0;
			endcase
		`LOAD : imm_val = {{52{instr[31]}}, instr[31:20]};
		`STORE : imm_val = {{52{instr[31]}}, instr[31:25], instr[11:7]};
		`BRANCH : imm_val = {{51{instr[31]}} , instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
		 default: imm_val = 64'b0;
	endcase
	end

	always @(*)
	begin
      if (instr[6:2] == `BRANCH) 
                case (instr[14:12])
                                3'b000: branch = 2'b11; //BEQ   
                                3'b001: branch = 2'b01; //BNE  
                                3'b100: branch = 2'b01; //BLT  
                                3'b101: branch = 2'b11; //BGE
                                default: branch = 2'b0;
                endcase
		else branch = 2'b0;
	end
	
	always @(*)
	begin
      if(instr[6:2] == `LOAD)	mem_out_wb = 1;
		else mem_out_wb = 0;
	end

	always @(*)
	begin
      if(instr[6:2] == `STORE)	mem_w = 1;
		else mem_w = 0;
	end
	
	always @(*)
	begin
      if((instr[6:2] == `LOAD) || (instr[6:2] == `RTYPE ) || (instr[6:2] == `ITYPE))	reg_w = 1;
		else reg_w = 0;
	end
	
	always @(*)
	begin
      if((instr[6:2] == `LOAD) || (instr[6:2] == `ITYPE ) || (instr[6:2] == `STORE))	i_type = 1;
		else i_type = 0;
	end

	always @(*)
	begin
      if(instr[6:2] == `XORACC) 
			xor_acc_en = 1;
		else
			xor_acc_en = 0;
	end

endmodule
