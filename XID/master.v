`timescale 1ns / 1ps

`include "RISCV_CPU.v"
`include "RISCV_CPU2.v"
`include "dual_fifo_fsm.v"
`include "bloom_fsm.v"

module master(
	 input clk,
    input reset,
	 //netfpga module io
    input [63:0] in_data,
    input [7:0] in_ctrl,
    input in_wr,
    output in_rdy,
    output [63:0] out_data,
    output [7:0] out_ctrl,
    output out_wr,
    input out_rdy,
	 //debugging interface
	 input [7:0] memAdressQuery,
	 output [7:0] memDataOut_cntrl,
	output [31:0] memDataOut_msb,
	output [31:0] memDataOut_lsb,
  output [8:0] pc_out_1,
  output [8:0] pc_out_2,
  output [7:0] w_ptr, w_ptr_prev,
  output [3:0] state,
  //Bloom filter 
  input [63:0] filter,
  output [7:0] count
    );



	//some delarations
	//memory related
  wire [7:0] memory_address_1;
  wire [63:0] memory_data_in_1;
  wire [63:0]memory_data_out_1;
	wire memory_wea_1;
	wire memory_enable_1;
	//enable and disbale stuff
	wire proc_en, proc_di_1;
  wire [7:0] r_ptr;
  	//wire [7:0] w_ptr_prev;
  
  wire [7:0] memory_address_2;
  wire [63:0] memory_data_in_2;
  wire [63:0]memory_data_out_2;
	wire memory_wea_2;
	wire memory_enable_2;
	//enable and disbale stuff
	wire proc_di_2;

	
  //Bloom Filter Stuff --
  
  wire bloom_match;
  wire good_to_go;
  reg bloom_match_latch;
  wire all_proc_done;
  wire bloom_proc_en;
  
  bloom_bloom_fsm u_bloom_fsm ( 
    .in_data(in_data),
    .in_ctrl(in_ctrl),
    .filter(filter),
    .clk(clk), .reset(~reset),
    .bloom_match(bloom_match));
  
  //Bloom Filter latch and release logic
  assign all_proc_done = proc_di_1 & proc_di_2;
  assign good_to_go = all_proc_done | ~bloom_match_latch;
  assign bloom_proc_en = proc_en & bloom_match_latch;
  
  always @ (posedge clk, negedge reset) begin
    if (~reset) begin
      bloom_match_latch <= 0;
    end else if (all_proc_done) begin
      bloom_match_latch <= 0;
      end else begin
      bloom_match_latch <= (bloom_match | bloom_match_latch) & ~all_proc_done;
    end
  end
  
      
       
	//fsm instantiation 
	fsm u_fifo_fsm (
    .clk(clk),
    .reset(reset),
      //Output to CPU & IDS
      .wp(w_ptr),
      .rp(r_ptr),
      .wp_prev(w_ptr_prev),
	 //netfpga module io
    .in_datai(in_data),
    .in_ctrli(in_ctrl),
    .in_wri(in_wr),
    .in_rdy(in_rdy),
    .out_data(out_data),
    .out_ctrl(out_ctrl),
    .out_wr(out_wr),
    .out_rdy(out_rdy),
	 //Core 1 interface
      .proc_data_in(memory_data_in_1),
      .proc_addr_in(memory_address_1),
      .proc_data_out(memory_data_out_1),
      .proc_web(memory_wea_1),
      //Core 2 Interface
      .proc2_data_in(memory_data_in_2),
      .proc2_addr_in(memory_address_2),
      .proc2_data_out(memory_data_out_2),
      .proc2_web(memory_wea_2),
      //
      .proc_memEn(1'b1),
      .pin_di(good_to_go),
      .p_en(proc_en),
	 //debugging pins
	 .memAdressQuery(memAdressQuery),
      .memDataOut({memDataOut_cntrl,memDataOut_msb,memDataOut_lsb}),
      .state(state),
      .count(count)
    );
	
  wire core2_match;

  RISCV u_cpu_core1 (
    .clk(clk),
    .rst(reset),
    .enable(1'b1),
    .pc_out(pc_out_1),
    .data_mem_out_i(memory_data_out_1),
    .cpu_mem_addr_o(memory_address_1), 
    .cpu_mem_din_o(memory_data_in_1), 
    .cpu_mem_wena_o(memory_wea_1),
    .w_ptr(w_ptr), .r_ptr(r_ptr), .w_ptr_prev(w_ptr_prev), .p_en(bloom_proc_en), .pi_di(proc_di_1), .core2_match(core2_match), .all_proc_done(all_proc_done), .count(count)
    );

    RISCV_2 u_cpu_core2 (
    .clk(clk),
    .rst(reset),
    .enable(1'b1),
      .pc_out(pc_out_2),
      .data_mem_out_i(memory_data_out_2),
      .cpu_mem_addr_o(memory_address_2), 
      .cpu_mem_din_o(memory_data_in_2), 
      .cpu_mem_wena_o(memory_wea_2),
      .w_ptr(w_ptr), .r_ptr(r_ptr), .w_ptr_prev(w_ptr_prev), .p_en(bloom_proc_en), .pi_di(proc_di_2), .core2_match(core2_match), .all_proc_done(all_proc_done), .count(count)
    );

  
endmodule
