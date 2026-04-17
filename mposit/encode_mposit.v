// Copyright 2026 SangKyun Yun, Junryul Yang, and Woocheol Jung
// encode_mposit : mPosit Encoder

`define NSIZE 32		// 32, 16, or 8

module encode_mposit(sign, frac, exp, special, out);
	parameter N=`NSIZE;
	parameter ES=2;
	localparam W = $clog2(N);
	localparam FS=N-ES-1;	// fraction size : (N-ES-3) bit fraction + Round, Sticky bits (2-bits)
	input sign;				// sign
	input [FS-1:0] frac;	// lowest 2-bits : Round, Sticky bit
	input [W+ES:0] exp;
	input special;
	output [N-1:0] out;
	
	wire [W:0] exp_h;		// upper exponent
	wire [ES-1:0] exp_l;	// lower exponent
	wire [W-1:0] sc;		// shift count
	wire [N-2:0] mk1;		// pos regime (N-1 bits)
	wire [N:0]   mk2; 		// neg regime (N+1 bits)
	wire [N-2:0] mask;		// mask (exp, fraction field)
	wire [N-2:0] regime;	// regime
	wire [N-2:0] EFR, K;	// combined exp, fraction, regime output
	wire sign_o;
	
	// upper and lower exponent
	assign exp_h = exp[W+ES:ES];	
	assign exp_l = exp[ES-1:0];
	
	// encoding
	assign sc = exp_h[W] ? ~exp_h[W-1:0] : exp_h[W-1:0];		// shift count (from 0)
	
	// generate regime patterns and non-regime mask
	assign mk2 = 'b10 << sc;			// negative regime: 0..010, 0..0100, ... , 010..0, 10..00, 0..00
	assign mk1 = ~('h1FFFFFFFE << sc);	// positive regime: 0..001, 0..0011, ... , 001..1, 01..11, 1..11
	assign mask = ~(mk2[N-2:0] | mk1);	// non-regime mask:   1..100, 1..1000, ... , 100..0, 00..00, 0..00	
	
	// rounding to nearest even  (RNE)
	wire ulp;							// unit at last place
	wire [N-1:0] frac_only;				// exclude the lowest two bits (round and stick bit)
	
	assign frac_only = { {(N-FS+2){1'b1}}, frac[FS-1:2] };	// N-bits
	assign ulp = frac_only[sc];		// MUX selected by sc, output ULP of the kept fraction

	wire [FS-1:0] mk1_round;
	wire [FS-1:0] frac_o;
	wire [ES-1:0] exp_o;
	wire carry;				// exponent overflow
	
	assign mk1_round = { 1'b0, mk1[FS-2:0] };		// addend for RNE 
	assign {carry, exp_o, frac_o} = {exp_l, frac} + mk1_round + ulp;
	
	// regime
	wire [N-2:0] mk1_o;
	wire [N:0] mk2_o;
	wire [N-2:0] mk2_s; 

	assign mk1_o = carry ? { mk1[N-3:0], 1'b1 } : mk1;	// if overflow, shift left with one fill
	assign mk2_o = carry ? {1'b0, mk2[N:1] } : mk2;		// if overflow, shift right with zero fill
	assign mk2_s= {|mk2_o[N:N-2], mk2_o[N-3:0]};		// for negative saturation

	assign regime = exp_h[W] ? mk2_s : mk1_o;			// convert zero regime to non-zero regime	

	assign EFR =  ({exp_o, frac_o} & mask) | regime;	// combined fraction and regime field
	assign K = special ? 0 : EFR;
	assign out = {sign, K};
endmodule
