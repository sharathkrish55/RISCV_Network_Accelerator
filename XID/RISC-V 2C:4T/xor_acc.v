module xor_comp (
  input [55:0] A, B,
  output match);
  
  assign match = (A == B);
  
endmodule


module xor_acc (
  input [63:0] curr, prev,
  input match_en, core,
  input [1:0] thread_select,
  output match);
  
  //Concatenating the packets together
  wire [111:0] data = {prev[47:0], curr};
  
  //Pattern for each core/thread --
  reg [55:0] patt;
  
  //Creating wires for the match output
  wire match_1, match_2, match_3, match_4, match_5, match_6, match_7, match_8;
  
  assign match = (match_1 | match_2 | match_3 | match_4 | match_5 | match_6 | match_7 | match_8) & match_en;

  //Instatiating the XOR comparators
  xor_comp u_xor_comp1 (.A(data[55:0]), .B(patt), .match(match_1));
  xor_comp u_xor_comp2 (.A(data[63:8]), .B(patt), .match(match_2));
  xor_comp u_xor_comp3 (.A(data[71:16]), .B(patt), .match(match_3));
  xor_comp u_xor_comp4 (.A(data[79:24]), .B(patt), .match(match_4));
  xor_comp u_xor_comp5 (.A(data[87:32]), .B(patt), .match(match_5));
  xor_comp u_xor_comp6 (.A(data[95:40]), .B(patt), .match(match_6));
  xor_comp u_xor_comp7 (.A(data[103:48]), .B(patt), .match(match_7));
  xor_comp u_xor_comp8 (.A(data[111:56]), .B(patt), .match(match_8));
  
  
  
  //Pattern generator per core/thread --
    always @ (*) begin
    
    case (core)
      1'b0: begin
        
        case (thread_select)
          2'b00: patt = 56'h77777777777777; //Thread 2
          2'b01: patt = 56'h54545454545454; //Thread 3 -- Invalid
          2'b10: patt = 56'h68686868686868; //Thread 0
          2'b11: patt = 56'h75757575757575; //Thread 1
        endcase //case (ts)
        
      end
      
        
       1'b1: begin
        
        case (thread_select)
          2'b00: patt = 56'h74747474747474; //Thread 2
          2'b01: patt = 56'h78787878787878; //Thread 3
          2'b10: patt = 56'h67676767676767; //Thread 0
          2'b11: patt = 56'h54545454545454; //Thread 1
        endcase // case(ts)
         
       end
      
    endcase //Case (core)
      
  end //Always 

endmodule

                
                
