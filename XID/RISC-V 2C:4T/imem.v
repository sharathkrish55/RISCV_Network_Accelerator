//Core 1 - Instruction Memory
module i_mem1
  (   	input clka,    //Clock
        input wea,    //write enable for port 0
   		input [31:0] dina,    //Input data to port 0.
   		input [8:0] addra,  //address for port 0
   		output reg [31:0] douta //output data from port 1.
    );
  
//memory declaration.
  reg [31:0] ram [0:511];
  
  initial begin
    $readmemh("imem_init1.data", ram);
  end

//writing to the RAM
  always @ (posedge clka) begin
    if(wea == 1) begin   //check if write enable is ON
    ram[addra] <= dina;
    end
    
    douta <= ram[addra];
  
  end
  
endmodule

//Core 2 - Instruction Memory
module i_mem2 
  (   	input clka,    //Clock
        input wea,    //write enable for port 0
   		input [31:0] dina,    //Input data to port 0.
   		input [8:0] addra,  //address for port 0
   		output reg [31:0] douta //output data from port 1.
    );
  
//memory declaration.
  reg [31:0] ram [0:511];
  
  initial begin
    $readmemh("imem_init_2.data", ram);
  end

//writing to the RAM
  always @ (posedge clka) begin
    if(wea == 1) begin   //check if write enable is ON
    ram[addra] <= dina;
    end
    
    douta <= ram[addra];
  
  end
  
  
endmodule
