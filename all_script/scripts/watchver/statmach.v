module statmach (CLK, RESET, STRTSTOP, locked, CLKEN, RST);
input CLK, RESET, STRTSTOP, locked;
output CLKEN, RST;

reg CLKEN_NEXT, RST_NEXT;
reg CLKEN, RST;
   
parameter
      clear = 6'b000001,
       zero = 6'b000010,
      start = 6'b000100,
   counting = 6'b001000,
       stop = 6'b010000,
    stopped = 6'b100000;

reg [5:0] current_state /* synthesis syn_state_machine = 1 */;
reg [5:0] next_state;

// RST AND CLKEN MUST BE REGISTERED TO PREVENT GLITCHING!

always@(current_state or STRTSTOP or locked)
  begin
     case (current_state)
      clear : begin
                next_state <= zero;
                RST_NEXT <= 1'b1;
					 CLKEN_NEXT <= 0;
              end
      zero  : begin
		        next_state <= (STRTSTOP & locked) ? start : zero;	    
              RST_NEXT <= 0;
    			  CLKEN_NEXT <= 0;
				  end
      start : begin
		        next_state <= (STRTSTOP & ~locked) ? start : counting;
              RST_NEXT <= 0;
    			  CLKEN_NEXT <= 0;
				  end
     counting : begin
                  next_state <= (STRTSTOP & ~locked) ? stop : counting;
                  RST_NEXT <= 0;
                  CLKEN_NEXT <= 1'b1;
                end
        stop : begin
					next_state <= (STRTSTOP) ? stop : stopped;
              RST_NEXT <= 0;
    			  CLKEN_NEXT <= 0;
					end
     stopped : begin
					next_state <= (STRTSTOP & locked) ? start : stopped;
              RST_NEXT <= 0;
    			  CLKEN_NEXT <= 0;
					end
     default : begin
					next_state <= clear; 
              RST_NEXT <= 0;
    			  CLKEN_NEXT <= 0;
					end
    endcase
  end
   
always @ (posedge CLK or posedge RESET)
      begin
	 if (RESET == 1'b1) begin
	    current_state = clear;
		 RST = 0;
		 CLKEN = 0;
		 end
	 else begin
	    current_state = next_state;
		 RST = RST_NEXT;
		 CLKEN = CLKEN_NEXT;
		 end
      end

endmodule
