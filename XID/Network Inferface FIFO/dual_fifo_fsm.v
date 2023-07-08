`timescale 1ns / 1ps

`include "MemBlock.v"

module fsm(
    input clk,
    input reset,
  output reg [7:0] wp,
  output reg [7:0] rp,
  //Added by sharkris
  output reg [7:0] wp_prev,
	 //netfpga module io
    input [63:0] in_datai,
    input [7:0] in_ctrli,
    input in_wri,
    output reg in_rdy,
    output reg [63:0] out_data,
    output reg [7:0] out_ctrl,
    output reg out_wr,
    input out_rdy,
	 //processor 1 interface
  	input [63:0] proc_data_in,
  	input [7:0] proc_addr_in,
	output reg [63:0] proc_data_out,
  	
  	//processor 2 interface
  	input [63:0] proc2_data_in,
  	input [7:0] proc2_addr_in,
  	output reg [63:0] proc2_data_out,
  	input proc2_web,
  
  
	 input proc_web,
	 input proc_memEn,
  
	 input pin_di,
	 output reg p_en,
	 //debugging pins
	 input [7:0] memAdressQuery,
  output [71:0] memDataOut,
  output reg [3:0] state,
  output reg [7:0] count
    );
	
	
	//timings testing
   reg [63:0] in_data;
   reg [7:0] in_ctrl;
   reg in_wr;
   
  	// Check
  reg [8:0] packet_count;
	
	//
	always@(posedge clk)
	begin
		in_data <= in_datai;
		in_ctrl <= in_ctrli;
		in_wr <= in_wri;
	end

	
	
	parameter IDLE = 4'b0001, RX = 4'b0010, EX = 4'b0100, TX = 4'b1000;
	
	reg [3:0] next_state;
	reg out_wr_w;
	//reg [7:0] count;
	//reg [7:0] wp;
	//reg [7:0] rp;
	reg p_di, count_pi;
	
	//Interface to memory block
	reg [7:0] addrb;
	reg [71:0]	dinb;
	wire [71:0] doutb;
	reg web, enb;
  	
  	//Interface to proc2 memory block
  	reg [7:0] proc2_addrb;
  	reg [71:0] proc2_dinb;
  	wire [71:0] proc2_doutb;
  	reg web_proc2;
  
  	//Interface 
	wire control_nonzero;



	
// The actual memory block - Core 1 Master
	MemBlock fifo1 (
		.addra(memAdressQuery), // Bus [7 : 0] 
		.addrb(addrb), // Bus [7 : 0] 
		.clka(clk),
		.clkb(clk),
		.dina(72'b0), // Bus [71 : 0] 
		.dinb(dinb), // Bus [71 : 0] 
		.douta(memDataOut), // Bus [71 : 0] 
		.doutb(doutb), // Bus [71 : 0] 
		.enb(enb),
		.wea(1'b0),
		.web(web));
  
  
// The second Memory block for Core 2
	MemBlock fifo2 (
		.addra(memAdressQuery), // Bus [7 : 0] 
      	.addrb(proc2_addrb), // Bus [7 : 0] 
		.clka(clk),
		.clkb(clk),
		.dina(72'b0), // Bus [71 : 0] 
      	.dinb(proc2_dinb), // Bus [71 : 0] 
		.douta(), // Bus [71 : 0] 
      	.doutb(proc2_doutb), // Bus [71 : 0] 
		.enb(enb),
		.wea(1'b0),
      .web(web_proc2));
	

	
	//ctrl_nonzero logic 
	assign ctrl_nonzero = (in_ctrl[7] | in_ctrl[6] | in_ctrl[5] |in_ctrl[4] |in_ctrl[3] |in_ctrl[2] |in_ctrl[1] |in_ctrl[0]);
	

	// pi_di stuff
	always @(posedge clk or negedge reset)
	begin
		if(~reset)
		begin
			p_di <= 1'b0;
			count_pi <= 1'b0;
		end
		else
		begin
			p_di <= count_pi;
			if (pin_di == 1'b1)
				count_pi <= 1'b1;
			else if (~(count <= 1'b0))
				count_pi <= 1'b0;
		end
	end


	
	//Combinational block
	always@(*)
	begin
		case(state)
		
		IDLE : 
		begin
			in_rdy = 1'b1;
			p_en = 1'b0;
			out_wr_w = 1'b0;
			//mem-block
			enb = 1'b1;
			addrb = wp;
          	proc2_addrb = wp;
			dinb = {in_ctrl, in_data};
          	proc2_dinb = {in_ctrl, in_data};
          
			{out_ctrl, out_data} = doutb;

          
			if(in_wr == 1'b1)
			begin
				next_state = RX;
				web = 1'b1;
              	web_proc2 = 1'b1;
				//store headpointer info in register 29
			end
			else
			begin
				next_state = IDLE;
				web = 1'b0;
              	web_proc2 = 1'b0;
			end
		end
		
		RX:
		begin
			in_rdy = ~ctrl_nonzero;
			p_en = 1'b0;
			out_wr_w = 1'b0;
			//memblock operations
			enb = 1'b1;
          	
          	//Core 1 Master
			addrb = wp;
			dinb = {in_ctrl, in_data};
			{out_ctrl, out_data} = doutb;
          
          
          	//Core 2 Slave
			proc2_addrb = wp;
			proc2_dinb = {in_ctrl, in_data};
          
			if(in_wr == 1'b1)
			begin
				web = 1'b1;
              	web_proc2 = 1'b1;
              
				if(ctrl_nonzero == 1'b0)
					next_state = RX;
					//store depth info in register 28
				else
					next_state = EX;
			end
			else
			begin
				web = 1'b0;
              	web_proc2 = 1'b0;
              
				next_state = RX;
			end
		end
		
		EX:
		begin
			in_rdy = 1'b0;
			out_wr_w = 1'b0;
			p_en = ~p_di;
			//mem block operations
          
          	//Core 1 Master
			addrb = proc_addr_in;
			enb =  proc_memEn;
			web =  proc_web;
			dinb = {{8{1'b0}},proc_data_in};
			proc_data_out = doutb[63:0];
          
          	//Core 2 Slave
			proc2_addrb = proc2_addr_in;
			enb =  proc_memEn;
			web_proc2 =  proc2_web;
          	proc2_dinb = {{8{1'b0}},proc2_data_in};
			proc2_data_out = proc2_doutb[63:0];
          
			if(p_di == 1'b1)
				next_state = TX;
			else 
				next_state = EX;	
		end
		
		TX:
		begin
			p_en = 1'b0;
			in_rdy = 1'b0;
			//mem block operations
          
          	//Core 1 Master 
			enb = 1'b1;
			addrb = rp;
			web = 1'b0;
			dinb = {in_ctrl, in_data};
			{out_ctrl, out_data} = doutb;
          
            //Core 2 Slave
			proc2_addrb = rp;
			web_proc2 = 1'b0;
			proc2_dinb = {in_ctrl, in_data};
          
			if(out_rdy == 1'b1)
			begin
				out_wr_w = 1'b1;
				if(count == 8'd1)
					next_state = IDLE;
				else 
					next_state = TX;
			end
			else
			begin
				out_wr_w = 1'b0;
				if(count == 8'd1)
					next_state = TX;
				else
					next_state = TX;	
			end
		end
		
		endcase
	end
	
	
	//Sequential block
	always@(posedge clk, negedge reset)
	begin
		if(~reset)
		begin
			state <= IDLE;
			count <= 8'd0;
			wp <= 8'd0;
          	wp_prev <= 8'd0;
			rp <= 9'd0;
			//p_di <= 1'b0;
			packet_count <= 9'd0;
		end	
		else
		begin
			state <= next_state;
			//another case statement for sequential elements
			case(state)
				IDLE : 
				begin
                    wp_prev <= wp;
                  
					if(in_wr == 1)
					begin
						count <= count + 1;
						wp <= wp+1;
						packet_count <= packet_count + 1;
					end
				end
				
				RX:
				begin
					if(in_wr == 1'b1)
					begin
						count <= count + 1;
						wp <= wp + 1;
					end
				end
				
				EX:
				begin
				end
				
				TX:
				begin
					if(out_rdy == 1)
					begin
						rp <= rp + 1;
						count <= count - 1;
					end
			end
			endcase
		end	
	end
	
	

	//verilog semantics nuisance handling for out_wr
	always@(posedge clk or negedge reset)
	begin
		if(~reset)
			out_wr <= 1'b0;
		else
			out_wr <= out_wr_w;
	end

endmodule
