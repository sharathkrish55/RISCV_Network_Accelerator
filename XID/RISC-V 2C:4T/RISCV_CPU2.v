`timescale 1ns / 1ps

module RISCV_2 (
	input clk,
	input rst,
	input enable,
  output wire [8:0] pc_out,
  input wire [63:0] data_mem_out_i,
  output wire [7:0] cpu_mem_addr_o, 
  output wire [63:0] cpu_mem_din_o, 
  output wire cpu_mem_wena_o,
  //Wires for polling
  input wire [7:0] w_ptr, r_ptr, w_ptr_prev,
  input wire p_en,
  output wire pi_di,
  output core2_match,
  input all_proc_done,
  input wire [7:0] count
    );


   //Stage Registers
  reg [10:0] IF_ID;
  reg [88:0] ID_EX;
  reg [200:0] EX_MEM;
  reg [70:0] MEM_WB;
  
	//Program Counter
	wire [8:0] PC;
  	reg [8:0] PC_arr [3:0];
  	
	//Wires
	wire [31:0] instr_mem_out;
  	wire [4:0] waddr;
	wire [63:0] wdata;
	wire wena;
  //regfile changes
  wire [63:0] r0data_rf;
  reg [63:0] r0data_reg;
  wire [63:0] r0data, r1data;
  //regfile changes end
	wire [63:0] data_mem_out;
	wire [3:0] aluop;
	wire reg_w;
	wire mem_w;
	wire i_type;
	wire [63:0] imm_val;
	wire mem_out_wb;
	wire [1:0] branch;
	wire [63:0] alu_res;
	wire [8:0] target_addr;
	wire [63:0] alu_b_in;
	wire branch_alu, branch_outcome;
	reg [1:0] thread_select;  
  


	//Fetch
  //PC Logic Start --
  always @(posedge clk, negedge rst) begin
    
    			if(~rst)
                        thread_select <= 0;
                else
                        thread_select <= thread_select + 1;
        end 

  //Assigning PC net to PC_arr :        	
  	assign PC = ~rst ? 0 : PC_arr[thread_select];
           
  wire branch_debug = EX_MEM[199];
  wire [31:0] branch_target_debug = EX_MEM[198:135];

  always @ (posedge clk, negedge rst) begin
    		if (~rst) begin
      			PC_arr[0]   <= 0;
              PC_arr[1]   <= 16;
              PC_arr[2]   <= 32;
              PC_arr[3]   <= 48;
      
            end else if (EX_MEM[199] != 0) begin
        
      			case(thread_select)
                  2'b00: begin
                    	PC_arr[1] <= EX_MEM[198:135];
                  end
                  2'b01: begin
                    	PC_arr[2] <= EX_MEM[198:135];
                  end
                  2'b10: begin
                    	PC_arr[3] <= EX_MEM[198:135];
                  end
                  2'b11: begin
                    	PC_arr[0] <= EX_MEM[198:135];
                  end
                  
      			endcase
              
              	PC_arr[thread_select] <= PC_arr[thread_select] + 1;
      
            end else begin
      
      			PC_arr[thread_select] <= PC_arr[thread_select] + 1;
    		end
  
		end

     assign pc_out = PC;

  //PC Logic END --
  
  
  
  
	/*Instantiation of Instruction Memory 512 x 32 */
	i_mem2 u_imem ( .addra(PC), .clka(clk), .dina(32'h0), .wea(1'b0), .douta(instr_mem_out));

  always @(posedge clk, negedge rst)
	begin
      if(~rst)
			IF_ID <= 0;
		else if(enable)
		begin
          IF_ID[8:0] <= PC;
			IF_ID[10:9] <= thread_select;
		end
	end
	
	//Decode
  
  //RF Write extension : 
  reg [3:0] pkt_processed;
  
  always @ (posedge clk, negedge rst) begin
    
    if (~rst)
      pkt_processed <= 0;
    
    else if (all_proc_done)
      pkt_processed <= 0;
    
    else if (wena & waddr[4] & waddr[1]) begin
      case  (thread_select)
        2'b00: pkt_processed <= pkt_processed | 4'b0001;
        2'b01: pkt_processed <= pkt_processed | 4'b0010;
        2'b10: pkt_processed <= pkt_processed | 4'b0100;
        2'b11: pkt_processed <= pkt_processed | 4'b1000;
      endcase
    end
    
  end
    
    assign pi_di = &pkt_processed;
  
    wire wena_rf = wena & ~waddr[4];
  
  wire [3:0] rs1_addr = instr_mem_out[18:15];

  reg match;

  always @ (posedge clk, negedge rst) begin

   	if(~rst)
		match<=0;
   	else if (wena & waddr[4] & ~waddr[1])
		match <= 1'b1;
   end


  	reg_file_64X64 rf1 (.clka(clk), .dina(wdata), .addra({thread_select,waddr[3:0]}), .wea(wena_rf), .clkb(clk), .addrb({IF_ID[10:9],rs1_addr}), .doutb(r0data_rf));
  
  always @ (*) begin
    case (instr_mem_out[17:15])
		3'b000: r0data_reg = w_ptr;
		3'b001: r0data_reg = r_ptr;
    	3'b010: r0data_reg = {7'b0, p_en};
      	3'b011: r0data_reg = {4'b0, pkt_processed};	
      	3'b100: r0data_reg = count;
      	default: r0data_reg = count;
  	endcase
  end
    
  reg [7:0] r0data_reg_dly;
  reg reg_ext_en;
  
  always @ (posedge clk) begin
    r0data_reg_dly <= r0data_reg;
    reg_ext_en <= instr_mem_out[19];
  end
  
  wire [3:0] rs2_addr = instr_mem_out[23:20];
  
  reg_file_64X64 rf2 (.clka(clk), .dina(wdata), .addra({thread_select,waddr[3:0]}), .wea(wena_rf), .clkb(clk), .addrb({IF_ID[10:9],rs2_addr}), .doutb(r1data));
  
  //assigning rs1 extended address :
  assign r0data = reg_ext_en ? {56'b0, r0data_reg_dly} : r0data_rf;
 
	//Control Unit
	wire xor_acc_en;
  
	control_unit u_control_unit(
				.instr(instr_mem_out), 
				.aluop(aluop), 
				.reg_w(reg_w), 
				.mem_w(mem_w), 
				.i_type(i_type), 
				.imm_val(imm_val), 
				.mem_out_wb(mem_out_wb), 
      			.branch(branch),
      			.xor_acc_en(xor_acc_en));

  always @(posedge clk, negedge rst)
	begin
      if(~rst)
			ID_EX <= 0;
		else if(enable) 
		begin
          	ID_EX[3:0] <= instr_mem_out[10:7]; //rd
			ID_EX[7:4] <= aluop; //4
			ID_EX[8] <= reg_w;
			ID_EX[9] <= mem_w;
			ID_EX[10] <= i_type;
			ID_EX[74:11] <= imm_val;
			ID_EX[75] <= mem_out_wb;
			ID_EX[77:76] <= branch;
			ID_EX[86:78] <= IF_ID[8:0]; //pc
          ID_EX[87] <= instr_mem_out[11]; //RF Extension
          ID_EX[88] <= xor_acc_en;
		end
	end

	//Execute

	assign alu_b_in = ID_EX[10] ? ID_EX[74:11] : r1data;
  
    //XOR Accelerator --
  	wire acc_match;
  	xor_acc u_xor_acc (.curr(r0data), .prev(r1data), .match(acc_match), .match_en(ID_EX[88]), .thread_select(thread_select), .core(1'b1));
  	
  	assign core2_match = acc_match;
  	//
  
  	//Zero for branch --
  	wire zero;

  alu u_alu(.A(r0data), .B(alu_b_in), .aluop(ID_EX[7:4]), .result(alu_res), .zero(zero), .negative(), .overflow());

	assign target_addr = ID_EX[86:78] + (ID_EX[74:11]>>2); 		
	assign branch_outcome = ID_EX[76] & branch_alu;
  assign branch_alu = (ID_EX[77]) ? zero : ~zero;
	
  always @(posedge clk, negedge rst)
	begin
      if(~rst)
			EX_MEM <= 0;
		else if(enable)
		begin
			EX_MEM[3:0] <= ID_EX[3:0]; //rd
			EX_MEM[4] <= ID_EX[8]; //reg_w
			EX_MEM[5] <= ID_EX[9]; //mem_w
			EX_MEM[69:6] <= alu_res;
			EX_MEM[133:70] <= r1data; //r1data
			EX_MEM[134] <= ID_EX[75]; //mem_out_wb
        	EX_MEM[198:135] <= target_addr; // target address for late branch
          EX_MEM[199] <= branch_outcome & ID_EX[76]; //branch outcome for late branch
          EX_MEM[200] <= ID_EX[87]; //RF extension
		end
	end
	
	//Memory
//		/*Instantiation of Data Memory*/
//		d_mem XLXI_1 (  
//				.addra(EX_MEM[13:6]),
//			 	.addrb(address_reg),
//				.clka(clk), 
//				.clkb(clk), 
//				.dina(EX_MEM[133:70]), 
//				.wea(EX_MEM[5]),
//				.douta(data_mem_out),
//				.dinb(64'b0),
//				.web(1'b0),
//				.doutb({read_data_msb,read_data_lsb}));
  
  //Memory interface to external world start -
  assign cpu_mem_addr_o = EX_MEM[13:6];
  assign cpu_mem_din_o = EX_MEM[133:70];
  assign cpu_mem_wena_o = EX_MEM[5];
  assign data_mem_out = data_mem_out_i;
  //Memory interface to external world end -
		
  always @(posedge clk, negedge rst)
		begin
          if(~rst)
				MEM_WB <= 0;
			else if(enable)
			begin
				MEM_WB[3:0] <= EX_MEM[3:0]; //rd
				MEM_WB[4] <= EX_MEM[4]; //reg_w
				MEM_WB[68:5] <= EX_MEM[69:6]; //alu_res
				MEM_WB[69] <= EX_MEM[134]; //mem_out_wb
              	MEM_WB[70] <= EX_MEM[200]; //RF Extension
			end
		end
		
		//Writeback
		
  		assign waddr = {MEM_WB[70], MEM_WB[3:0]};
		assign wdata = MEM_WB[69] ? data_mem_out : MEM_WB[68:5];
		assign wena = MEM_WB[4];
  
  
  wire [8:0] pc0 = PC_arr[0];
  wire [8:0] pc1 = PC_arr[1];
  wire [8:0] pc2 = PC_arr[2];
  wire [8:0] pc3 = PC_arr[3];
		
endmodule  




