// Hash function
  module hash_func (
    input [55:0] data,
    output reg [5:0] index_a, index_b, index_c
  );
    
    parameter HASH_A = 45;
    parameter HASH_B = 9123;

    always @(*) begin
      index_a = (HASH_A * data + HASH_B) % 64;
      index_b = ((HASH_A + data) * HASH_B) % 64;
      index_c = ((HASH_A + HASH_B) * data) % 64;

    end
  endmodule

