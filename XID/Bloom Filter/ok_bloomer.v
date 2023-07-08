`include "hash_func.v"

//Bloom Comparator
module bloom_comparator (
  input [55:0] in_data,
  input [63:0] filter,
  output match);
  
  wire [5:0] index_a, index_b, index_c;
  
  hash_func u_hash_func (.data(in_data), .index_a(index_a), .index_b(index_b), .index_c(index_c));
  
  assign match = filter[index_a] & filter[index_b] & filter[index_c];
  
endmodule

module ok_bloomer (
  input [63:0] in_data,
  input [63:0] filter,
  input clk, rst, match_en,
  output reg bloom_match);
  
  //Registers to store the data
  reg [63:0] curr_data, prev_data;
  reg [63:0] filter_reg;
  
  //Concatenating the packets together
  wire [111:0] data = {prev_data[47:0], curr_data};
  
  //Creating wires for the match output
  wire match_1, match_2, match_3, match_4, match_5, match_6, match_7, match_8;
  
  //Instantiating the Bloom Filters
  bloom_comparator u_bc_1 (.in_data(data[55:0]), .filter(filter), .match(match_1));
  
  bloom_comparator u_bc_2 (.in_data(data[63:8]), .filter(filter), .match(match_2));
  
  bloom_comparator u_bc_3 (.in_data(data[71:16]), .filter(filter), .match(match_3));

  bloom_comparator u_bc_4 (.in_data(data[79:24]), .filter(filter), .match(match_4));

  bloom_comparator u_bc_5 (.in_data(data[87:32]), .filter(filter), .match(match_5));

  bloom_comparator u_bc_6 (.in_data(data[95:40]), .filter(filter), .match(match_6));

  bloom_comparator u_bc_7 (.in_data(data[103:48]), .filter(filter), .match(match_7));
  
  bloom_comparator u_bc_8 (.in_data(data[111:56]), .filter(filter), .match(match_8));
  
  //Getting the Match Signal
  wire match = match_1 | match_2 | match_3 | match_4 | match_5 | match_6 | match_7 | match_8;
  
  
  //The clocking and reset logic
  always @ (posedge clk, posedge rst) begin
    if (rst) begin
      curr_data <= 0;
      prev_data <= 0;
      filter_reg <= 0;
    end else begin
      curr_data <= in_data;
      prev_data <= curr_data;
      filter_reg <= filter;
    end
  end
  
  wire match_logic = ~bloom_match & match_en & match;
  wire clock_en = match_logic;
  
  //Match hold logic
  always @ (posedge clk, posedge rst) begin
    if (rst) begin
      bloom_match <= 0;
    end else if (clock_en) begin
      bloom_match <= match_logic;
    end
  end
  
        
endmodule

