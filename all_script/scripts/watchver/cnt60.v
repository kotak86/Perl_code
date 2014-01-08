module cnt60(CE,CLK,CLR,LSBSEC,MSBSEC);
input CE;
input CLK;
input CLR;
output [3:0] LSBSEC;
output [3:0] MSBSEC;

wire msbce;
wire msbclr;
wire lsbtc;
wire msbtc;
   
   
smallcntr lsbcount(.CE(CE),.CLK(CLK),.CLR(CLR),.QOUT(LSBSEC));
smallcntr msbcount(.CE(msbce),.CLK(CLK),.CLR(msbclr),.QOUT(MSBSEC));

   assign lsbtc = (LSBSEC==4'b1001)?1'b1:1'b0;
   assign msbtc = (MSBSEC==4'b0110)?1'b1:1'b0;
   assign msbce = CE & lsbtc;
   assign msbclr = CLR | msbtc;
   
endmodule