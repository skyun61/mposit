// Testbench for decode_mposit 

`timescale 1ns / 1ps

module decode_mposit_tb;
	parameter N = 8;
	parameter ES = 2;			// fixed
	localparam W = $clog2(N);
//	localparam FS = N-ES-3;		// fraction field
	localparam N1 = N-1;

	wire [N-1:0] in;		// mposit format input
	wire sign;
	wire signed [W+ES:0] exp;
	wire [N-ES-1:0] efrac;	// include hidden bit
	wire special;
	
	decode_mposit #(N, ES) u1 (in, sign, exp, efrac, special);

	integer i;
	reg in_sign;
	reg [ES-1:0] in_e;		// ES bits
	reg [N-ES-2:0] in_f;	// N-ES-1 bits
	reg [N-2:0] regime, mask;
	reg [N-2:0] EFR;	

	initial begin
		$display(" ---------- decode mposit (%2d,%1d) -----------", N, ES);
		$display(" time : e  f     regime  : in :       exp         ef     s sp");
		$monitor("%5d : %2b %5b %7b : %8b : %6b(%3d) %b %b %b ", 
			$time,  in_e, in_f, regime, in, exp, exp,  efrac, sign, special);

		#1400
		$stop;
	end

	initial begin
		in_sign=1; EFR = 0;		// infinity
		#50 
		in_sign=0; EFR = 0;		// zero

		in_e = 'b11;			// lower exponent
		in_f = 'b11111;			// fraction
		// positive regimes
		regime = 'b01;			
		mask = ~'b11;			// non-regime mask
		for (i=1; i<=N-1; i=i+1) begin
			#50 
			EFR = {in_e, in_f} & mask | regime;
			regime = (regime << 1) | 'b1;	// one fill
			mask = mask << 1;
		end
		// negative regimes
		regime = 'b10;
		mask = ~'b11;			// non-regime mask
		for (i=1; i<N-1; i=i+1) begin
			#50 EFR = {in_e, in_f} & mask | regime;
			regime = (regime << 1);		// zero fill
			mask = mask << 1;
		end
	end

	assign in = {in_sign, EFR};	// decoder input
endmodule
