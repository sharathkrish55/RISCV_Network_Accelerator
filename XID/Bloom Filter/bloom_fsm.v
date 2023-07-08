`include "ok_bloomer.v"

module bloom_bloom_fsm (
  input [63:0] in_data,
  input [7:0] in_ctrl,
  input [63:0] filter,
  input clk, reset,
  output bloom_match);
  

  //Creating a match state machine
  parameter START = 3'b001;
  parameter HEADER = 3'b010;
  parameter PAYLOAD = 3'b100;
  
  //Signals used
  reg begin_pkt, begin_pkt_next;
  reg end_of_pkt, end_of_pkt_next;
  reg in_pkt_body, in_pkt_body_next;
  reg [2:0] state, state_next;
  reg [2:0] header_counter, header_counter_next;
    
  wire bloom_rst = reset | end_of_pkt;
  wire matcher_en = in_pkt_body;
  
  //Instantiating the Bloom Filter
  ok_bloomer u_bloom_filter (.in_data(in_data), .clk(clk), .rst(bloom_rst), .bloom_match(bloom_match), .match_en(matcher_en), .filter(filter));
  
  //FSM Combo logic
  always @ (*) begin
    state_next = state;
    header_counter_next = header_counter;
    end_of_pkt_next = end_of_pkt;
    in_pkt_body_next = in_pkt_body;
    begin_pkt_next = begin_pkt;
    
    
    case(state)
      START: begin
        if(in_ctrl != 0 ) begin
        	state_next = HEADER;
          	begin_pkt_next = 1;
        	end_of_pkt_next = 0; //Removes matcher from reset
        end
      end
        
      HEADER: begin
        begin_pkt_next = 0;
        if(in_ctrl == 0) begin
          header_counter_next = header_counter + 1'b1;
          if (header_counter_next == 3) begin
            state_next = PAYLOAD;
          end
      	end
      end
      
      
      PAYLOAD: begin
        if(in_ctrl != 0) begin
          state_next = START;
          header_counter_next = 0;
          end_of_pkt_next = 1; //Resets matcher
          in_pkt_body_next = 0;
        end
        else begin
          in_pkt_body_next = 1;
        end
      end
    endcase // ending case(state)
    
  end

  always @(posedge clk, posedge reset) begin
      if(reset) begin
         header_counter <= 0;
         state <= START;
         begin_pkt <= 0;
         end_of_pkt <= 0;
         in_pkt_body <= 0;
      end
      else begin
         header_counter <= header_counter_next;
         state <= state_next;
         begin_pkt <= begin_pkt_next;
         end_of_pkt <= end_of_pkt_next;
         in_pkt_body <= in_pkt_body_next;
      end // else: !if(reset)
   end // always @ (posedge clk)   

endmodule
        
        
      
      
      
        
        