// Copyright 2026 SangKyun Yun, Junryul Yang, and Woocheol Jung
// decode_mposit : mPosit Decoder

`define NSIZE 8				// 32, 16, or 8

module decode_mposit(in, sign, exp, efrac, special);	
	parameter N=`NSIZE;
	parameter ES=2;
	localparam W = $clog2(N);
	input [N-1:0] in;			// mposit format input
	output sign;
	output [W+ES:0] exp;
	output [N-ES-1:0] efrac;	// include hidden bit
	output special;				// special data : zero or infinity
	
	wire sign = in[N-1];				// sign bit
	wire special = (in[N-2:0] == 0);	// zero or infinity
	wire [N-2:0] EFR = in[N-2:0];		// combined exponent, fraction, regime field

// investigate regime field and extract upper exponent
	wire [N-1:0] cEFR = {2'b01, in[N-2:1] ^ in[N-3:0]};	// bit differences (leftmost: sentinel 1)
	wire [W-1:0] k; 		// trailing one bit position 
	wire [ES-1:0] expl;		// lower exponent
	wire [W:0] exph;		// upper exponent
	
	tod #(N) u1 (cEFR, k,  );		
	
	assign exph[W] = ~in[0];			// sign of exponent	(011..1: +, 10..0: -)
	assign exph[W-1:0] = in[0] ? k : ~k;

// extract lower exponent and fraction
	wire [N-2:0] EFR1;		// regime complement of EFR
	wire [N-2:0] exp_frac;	// clear regime field, remain exponent/fraction
	
	assign EFR1 = in[0] ? (EFR + 1'b1) : (EFR - 1'b1);	// ..01111 => ..10000, ..1000 => ..0111
	assign exp_frac = EFR & EFR1;				// clear regime field
	
	assign expl = exp_frac[N-2:N-ES-1];			// exponent field
	assign efrac = {~special, exp_frac[N-ES-2:0]};	// mantissa (1.f)
	assign exp = { exph, expl };
endmodule

// trailing one position detector
module tod(in, p, v);
	parameter N=32;		// N is 2's power
	localparam W = $clog2(N);
	input [N-1:0] in;
	output [W-1:0] p;		// position
	output v;				// valid
	
	generate
		if (N==2) begin
			assign v = in[1] | in[0];
			assign p[0] = in[1] & ~in[0];	// 10 -> 1, 00, 01, 11 -> 0
		end
		else if (N & (N-1)) begin
			//tod #(1<<W) ( {(1<<W) {1'b0} } | in, p, v);
			tod #(1<<W) ( {{((1<<W)-N){1'b0}}, in}, p, v);		
		end
		else begin
			wire [W-2:0] pL, pH;
			wire vL, vH;
			tod #(N>>1) u1 (in[(N>>1)-1:0], pL, vL);		// lower half input
			tod #(N>>1) u2 (in[N-1:(N>>1)], pH, vH);		// upper half input
			assign v = vH | vL;
			//assign p = vL ? { 1'b0, pL} : {vH, pH};
			assign p = vL ? { 1'b0, pL} : {1'b1, pH};
		end
	endgenerate
endmodule
