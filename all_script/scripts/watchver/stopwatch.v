//`timescale 1ns/1ns

module stopwatch (CLK, RESET, STRTSTOP, TENTHSOUT, ONESOUT, TENSOUT);

input CLK;
input RESET;
input STRTSTOP;
output [9:0] TENTHSOUT;
output [6:0] ONESOUT;
output [6:0] TENSOUT;

wire strtstopinv;
wire clkenable;
wire rstint;
wire [9:0] xcountout;
wire xtermcnt;
wire cnt60enable;
wire [3:0] lsbcnt;
wire [3:0] msbcnt;
wire [3:0] Q;

//Logic for DCM 
wire clk_dcm;
wire dcm_lock;

dcm1 Inst_dcm1 (
    .RST_IN(RESET), 
    .LOCKED_OUT(dcm_lock), 
    .CLKIN_IN(CLK), 
    .CLK0_OUT(clk_dcm), 
    .CLKIN_IBUFG_OUT()
    );

statmach MACHINE(.CLK(clk_dcm),
		 .RESET(RESET),
		 .STRTSTOP(strtstopinv),
		 .locked(dcm_lock),
		 .CLKEN(clkenable),
		 .RST(rstint));

tenths xcounter (
	.q(Q),
	.clk(clk_dcm),
	.thresh0(xtermcnt),
	.ce(clkenable),
	.ainit(rstint));

decode one_decode (.BINARY(Q), .ONE_HOT(xcountout));
	
cnt60 sixty(.CE(cnt60enable),
		 .CLK(clk_dcm),
		 .CLR(rstint),
	   	 .LSBSEC(lsbcnt),
		 .MSBSEC(msbcnt));

hex2led lsbled(.HEX(lsbcnt),.LED(ONESOUT));
hex2led msbled(.HEX(msbcnt),.LED(TENSOUT));

assign cnt60enable = xtermcnt & clkenable;
assign TENTHSOUT = ~xcountout;
assign strtstopinv = ~STRTSTOP;

endmodule
