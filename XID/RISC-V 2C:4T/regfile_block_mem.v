module reg_file_64X64 
  (   	input clka,
   	  	input clkb,	//clock
        input wea,  //write enable for port 0.
   		input [63:0] dina,    //Input data to port 0.
   		input [5:0] addra,  //address for port 0
  		input [5:0] addrb,  //address for port 1
   		output reg [63:0] doutb //output data from port 1.
    );

    
//memory declaration.
  reg [63:0] ram [0:63];

  //Initializing the memory :
  initial begin
    $readmemh("reg_file.data", ram);
  end
  //Initialization End.
  
  
//writing to the RAM
  always@(posedge clka) begin
  	if(wea == 1)    //check if write enable is ON
    	ram[addra] <= dina;
  end
  
  always @ (posedge clkb)
    begin
      doutb <= ram[addrb];
    end
  
  
endmodule

  
