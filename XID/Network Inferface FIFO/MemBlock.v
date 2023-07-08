module MemBlock 
  (   	input clka,
   	  	input clkb,	//clock
        input wea,    //write enable for port 0.
   		input web,	  //write enable for port 1.
   		input enb,
   input [71:0] dina,    //Input data to port 0.
   input [71:0] dinb,	  //Input data to port 1.
   		input [7:0] addra,  //address for port 0
   		input [7:0] addrb,  //address for port 1
   output reg [71:0] doutb, //output data from port 1.
   output reg [71:0] douta
    );

    
//memory declaration.
  reg [71:0] ram [0:255];

  //Initializing the memory :
  initial begin
    $readmemh("MemBlock_init.data", ram);
  end
  //Initialization End.
  
  
//writing to the RAM
  always@(posedge clka) begin
  	if(wea == 1)    //check if write enable is ON
    	ram[addra] <= dina;
  end
  
  always @ (posedge clka) begin
    douta <= ram[addra];
  end
  
  always @ (posedge clkb) begin
    
  if (enb == 1) begin  
    if (web == 1)
      ram[addrb] <= dinb;
  end
    
  end
  
  always @ (posedge clkb)
    begin
      doutb <= ram[addrb];
    end
  
  
endmodule

  
