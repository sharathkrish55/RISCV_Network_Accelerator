`timescale 1ns/1ps

`include "master.v"

`define UDP_REG_ADDR_WIDTH 16
`define CPCI_NF2_DATA_WIDTH 16
`define IDS_BLOCK_TAG 1
`define IDS_REG_ADDR_WIDTH 16


module ids_sim 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,
      
      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input                                reset,
      input                                clk
   );


  reg [8:0] pc_out_1, pc_out_2;
  reg [7:0] w_ptr;

master u_master(
    .clk(clk),
    .reset(~reset),
    .in_data(in_data),
    .in_ctrl(in_ctrl),
    .in_wr(in_wr),
    .in_rdy(in_rdy),
    .out_data(out_data),
    .out_ctrl(out_ctrl),
    .out_wr(out_wr),
    .out_rdy(out_rdy),
  .memAdressQuery(0),
  .memDataOut_cntrl(),
    .memDataOut_msb(),
    .memDataOut_lsb(),
  .pc_out_1(pc_out_1),
  .pc_out_2(pc_out_2),
  .w_ptr(w_ptr),
  .w_ptr_prev(),
  .filter(64'h0000080080000001),
  .state()
    );


endmodule

