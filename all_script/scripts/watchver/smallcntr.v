`timescale 1ns/1ns

module smallcntr(CE,CLK,CLR,QOUT);

input CE;
input CLK;
input CLR;
output [3:0] QOUT;

reg [3:0] QOUT = 4'b0;

always@(posedge CLK or posedge CLR)
   begin
      if(CLR)     
	 QOUT = 4'b0000;
      else if(CE)
	 if(QOUT==4'b1001)
	    QOUT=4'b0000;
         else
	    QOUT = QOUT + 1;
   end
   
endmodule
