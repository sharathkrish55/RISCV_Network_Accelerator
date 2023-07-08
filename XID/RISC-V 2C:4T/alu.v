`timescale 1ns / 1ps

`define DUMMY	4'h0
//Arithmetic
`define ADD		4'h1
`define SUB		4'h2
//Logical
`define AND		4'h3
`define OR		4'h4
`define XOR	   4'h5
//Shift
`define SLL		4'h6
`define SRL		4'h7
//Comparison
`define SLT		4'h8 //signed
`define SLTU	4'h9 //unsigned

module alu(A, B, aluop, result, zero, negative, overflow);

input [63:0] A;
input [63:0] B;
input [3:0] aluop;
output reg[63:0] result;
output zero, negative, overflow;

assign zero = (result == 64'b0);

assign negative = result[63];

always@(*) begin
	case(aluop)
		`XOR : result = (A ^ B);
		`ADD : result = (A + B);
		`SUB : result = (A - B);
		`AND : result = (A & B);
		`OR  : result = (A | B);
		`SLL : result = (A << B);
		`SRL : result = (A >> B);
		`SLTU : result = (A < B);
		`SLT : begin
				if(A[63]!=B[63]) begin
					if(A[63]<B[63]) result = 64'b0; 
					else result = 64'b1;
				end else begin
					if(A>=B) result = 64'b0;
					else result = 64'b1;
				end
			   end
		default : result = 64'b0;
	endcase
end

assign overflow = ~aluop[2] & aluop[1] &     
     ((~aluop[0] & ~A[63] & ~B[63] & result[63]) |
     (~aluop[0] & A[63] & B[63] & ~result[63]) |
     (aluop[0] & ~A[63] & B[63] & result[63]) |
     (aluop[0] & A[63] & ~B[63] & ~result[63]));

endmodule
