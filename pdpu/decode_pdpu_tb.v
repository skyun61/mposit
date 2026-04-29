`timescale 1ns / 1ps
`define N 8

module decode_pdpu_tb;
	parameter N = `N;
	parameter ES = 2;			// fixed
	localparam W = $clog2(N);
	localparam FS = N-ES-3;		// fraction field
//	localparam FS = N-ES-1;		// fraction field
	localparam N1 = N-1;

	wire [N-1:0] in;		// mposit format input
	wire sign;
	wire signed [W+ES:0] exp;
	wire [FS:0] efrac;	// include hidden bit
	wire special;
	
	wire [W-1:0] m;
	decode_pdpu #(N, ES) u1 (in, sign, exp, efrac, special);

	integer i;
	reg in_sign;
	reg [ES-1:0] in_e;	// ES bits
	
	reg [FS-1:0] in_f;		// N-ES-1 bits
	reg signed [N-2:0] REF;		// N-1 bits

	initial begin
		in_sign=1; REF = 0;
		#50 
		in_sign=0; REF = 0;
		#50
		in_e = 'b11;	
		in_f = 'b11111;
		REF = {2'b10, in_e, in_f[FS-1:2]};		// lowest positive regime
		for (i=2; i<=N-1; i=i+1) begin
			#50 
			REF = REF >>> 1;
		end
		#50
		REF = {2'b01, in_e, in_f}; 
		for (i=2; i<N-1; i=i+1) begin
			#50 
			REF = REF >> 1;
		end
	end
	
	assign in = {in_sign, REF};
	
	initial begin
		$display("-------- decode pdpu --------");
		$display("  time :   in   :  exp    ef s sp");
		$monitor("%5d : %8b : %6b(%3d) %b %b %b", 
			$time, in, exp, exp, efrac, sign, special);
//
//		$monitor("%5d : %8b : %6b(%3d) %b %b %b  : %b %b %b %b", 
//			$time, in, exp, exp, efrac, sign, special
//			, u1.rc, u1.regime, u1.expl, u1.mant);
		#1000 $stop;
	end
endmodule
