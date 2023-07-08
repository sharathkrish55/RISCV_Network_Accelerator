// Code your design here
module reg_file ( wdata,

                waddr, 

                r0data,

                r0addr, 

                r1data,

                r1addr, 

                wena, 

                RST,

                CLK

              );      

  input  [63:0]  wdata; 

  input  [3:0]  waddr, r0addr, r1addr; 

  input wena; 

  input CLK, RST; 

  output [63:0] r0data, r1data; 
      
  reg [63:0]  regFile [0:15];
  
  
  //Assigning the outputs :
  assign r0data = regFile[r0addr];
  assign r1data = regFile[r1addr];

  integer i; 

  always @ (posedge CLK, negedge RST) begin

    if (RST == 0) begin 

     for (i = 0; i < 16; i = i + 1) begin
       regFile [i] = 64'h0; 
   	 end

    end else begin //If not at reset
		
      	if(wena) begin
       
       		regFile [waddr] = wdata; 

     	end
    end


   end 

endmodule
