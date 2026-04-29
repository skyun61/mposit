// PACoGen posit encoder
// - based on part of the following source codes
//		https://github.com/manish-kj/PACoGen/blob/master/add/posit_add.v
//		https://github.com/manish-kj/PACoGen/blob/master/mult/posit_mult.v

`define NSIZE 8

// PACoGen
module encode_pacogen(sign, frac, exp, special, out);
	parameter N=`NSIZE;
	parameter ES=2;
	localparam W = $clog2(N);	
	localparam FS=N-ES-1;	
	input sign;
	input [FS-1:0] frac;			// 1.frac  (include round, sticky bits)
	input [W+ES:0] exp;	
	input special;				// isNaR ?
	output [N-1:0] out;
	
	//Exponent and Regime Computation
	wire [ES-1:0] e_o;
	wire [W-1:0] r_o;

	reg_exp_op #(ES, W) uut_reg_ro (exp[ES+W:0], e_o, r_o);	
	
	//Exponent and Mantissa Packing
	wire [2*N:0] tmp_o;
	assign tmp_o = { {N{~exp[ES+W]}}, exp[ES+W], e_o, frac, 1'b0};

//	wire [2*N-1+3:0] tmp_o;
//	generate
//		if(ES > 2)
//			assign tmp_o = { {N{~exp[ES+W]}}, exp[ES+W], e_o, frac[FS-1:ES-2], frac[ES-3:0]};
//		else 
//			assign tmp_o = { {N{~exp[ES+W]}}, exp[ES+W], e_o, frac, {(3-ES){1'b0}} };
//	endgenerate

	//Including/Pushing Regime bits in Exponent-Mantissa Packing
	wire [3*N:0] tmp1_o;
	DSR_right_N_S #(.N(3*N+1), .S(W)) dsr2 (.a({tmp_o,{N{1'b0}}}), .b(r_o), .c(tmp1_o));

	//Rounding RNE : ulp_add = G.(R + S) + L.G.(~(R+S))
	wire L = tmp1_o[N+2], G = tmp1_o[N+1], R = tmp1_o[N], St = |tmp1_o[N-1:0],
		 ulp = ((G & (R | St)) | (L & G & ~(R | St)));
	wire [N-1:0] rnd_ulp = {{N-1{1'b0}},ulp};

	wire [N:0] tmp1_o_rnd_ulp;
	add_N #(.N(N)) uut_add_ulp (tmp1_o[2*N:N+1], rnd_ulp, tmp1_o_rnd_ulp);
	wire [N-1:0] tmp1_o_rnd = (r_o < N-ES-2) ? tmp1_o_rnd_ulp[N-1:0] : tmp1_o[2*N:N+1];

	//Final Output
	wire [N-1:0] tmp1_oN = sign ? -tmp1_o_rnd : tmp1_o_rnd;
	wire [N-2:0] K = special ? 0 : tmp1_oN[N-1:1];
	assign out = {sign, K};

endmodule

module sub_N (a,b,c);
	parameter N=10;
	input [N-1:0] a,b;
	output [N:0] c;
	wire [N:0] ain = {1'b0,a};
	wire [N:0] bin = {1'b0,b};
	
	sub_N_in #(.N(N)) s1 (ain,bin,c);
endmodule

module sub_N_in (a,b,c);
	parameter N=10;
	input [N:0] a,b;
	output [N:0] c;
	
	assign c = a - b;
endmodule

module add_1 (a,mant_ovf,c);
	parameter N=10;
	input [N:0] a;
	input mant_ovf;
	output [N:0] c;
	
	assign c = a + mant_ovf;
endmodule

module add_N (a,b,c);
	parameter N=10;
	input [N-1:0] a,b;
	output [N:0] c;
	wire [N:0] ain = {1'b0,a};
	wire [N:0] bin = {1'b0,b};
	add_N_in #(.N(N)) a1 (ain,bin,c);
endmodule

module add_N_in (a,b,c);
	parameter N=10;
	input [N:0] a,b;
	output [N:0] c;
	assign c = a + b;
endmodule

module reg_exp_op (exp_o, e_o, r_o);
	parameter es=3;
	parameter Bs=5;
	input [es+Bs:0] exp_o;
	output [es-1:0] e_o;
	output [Bs-1:0] r_o;

	assign e_o = exp_o[es-1:0];

	wire [es+Bs:0] exp_oN_tmp;
	conv_2c #(.N(es+Bs)) uut_conv_2c1 (~exp_o[es+Bs:0], exp_oN_tmp);
	wire [es+Bs:0] exp_oN = exp_o[es+Bs] ? exp_oN_tmp[es+Bs:0] : exp_o[es+Bs:0];
	
	assign r_o = (~exp_o[es+Bs] || |(exp_oN[es-1:0])) ? exp_oN[es+Bs-1:es] + 1 : exp_oN[es+Bs-1:es];
endmodule

module conv_2c (a,c);
	parameter N=10;
	input [N:0] a;
	output [N:0] c;
	assign c = a + 1'b1;
endmodule

module DSR_right_N_S(a,b,c);
	parameter N=16;
	parameter S=4;
	input [N-1:0] a;
	input [S-1:0] b;
	output [N-1:0] c;

	wire [N-1:0] tmp [S-1:0];
	assign tmp[0]  = b[0] ? a >> 7'd1  : a; 
	genvar i;
	generate
		for (i=1; i<S; i=i+1) begin:loop_blk
			assign tmp[i] = b[i] ? tmp[i-1] >> 2**i : tmp[i-1];
		end
	endgenerate
	assign c = tmp[S-1];

endmodule
