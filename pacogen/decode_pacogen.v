// PACoGen posit decoder
// - based on data extraction part of the following source codes
//		https://github.com/manish-kj/PACoGen/blob/master/add/posit_add.v
//		https://github.com/manish-kj/PACoGen/blob/master/mult/posit_mult.v

`define NSIZE 8

module decode_pacogen(in, sign, exp, efrac, special);	
	parameter N=`NSIZE;
	parameter ES=2;
	localparam W = $clog2(N);
	input [N-1:0] in;			// posit format input
	output sign;
	output [W+ES:0] exp;
	output [N-ES-1:0] efrac;	// include hidden bit
	output special;				// special data : zero or infinity

	wire sign = in[N-1];
	wire zero_tmp = | in[N-2:0];
//	wire special = (in[N-2:0] == 0);

	wire rc;
	wire [W-1:0] regime;
	wire [ES-1:0] expl;
	wire [N-ES-1:0] mant;	
	wire [N-1:0] xin = sign ? -in : in;

	data_extract_v1 #(N, ES) u1 (xin, rc, regime, expl, mant);	

	wire [W:0] exph;

	assign exph = rc ? {1'b0, regime} : {1'b1, -regime};
	assign exp = {exph, expl};
	assign efrac = {zero_tmp, mant[N-ES-1:1]};
	assign special = ~zero_tmp;
//	assign efrac = {~special, mant[N-ES-1:1]};

endmodule

//------------------------------------------------------------------------------------
// data_extract_v1, DSR_left_N_S, LOD_N, LOD modules 
// are modules in the following source codes :
//		https://github.com/manish-kj/PACoGen/blob/master/add/posit_add.v
//		https://github.com/manish-kj/PACoGen/blob/master/mult/posit_mult.v

module data_extract_v1(in, rc, regime, exp, mant);
	function [31:0] log2;
	input reg [31:0] value;
		begin
			value = value-1;
			for (log2=0; value>0; log2=log2+1)
					value = value>>1;
		end
	endfunction

	parameter N=32;
	parameter es = 2;
	localparam Bs=log2(N);

	input [N-1:0] in;
	output rc;
	output [Bs-1:0] regime;
	output [es-1:0] exp;
	output [N-es-1:0] mant;

	wire [N-1:0] xin = in;
	assign rc = xin[N-2];

	wire [N-1:0] xin_r = rc ? ~xin : xin;

	wire [Bs-1:0] k;
	LOD_N #(.N(N)) xinst_k(.in({xin_r[N-2:0],rc^1'b0}), .out(k));

	assign regime = rc ? k-1 : k;

	wire [N-1:0] xin_tmp;
	DSR_left_N_S #(.N(N), .S(Bs)) ls (.a({xin[N-3:0],2'b0}),.b(k),.c(xin_tmp));
//	assign xin_tmp = {xin[N-3:0],2'b0} << k;
	
	assign exp= xin_tmp[N-1:N-es];
	assign mant= xin_tmp[N-es-1:0];
endmodule

module DSR_left_N_S(a,b,c);
	parameter N=16;
	parameter S=4;
	input [N-1:0] a;
	input [S-1:0] b;
	output [N-1:0] c;

	wire [N-1:0] tmp [S-1:0];
	assign tmp[0]  = b[0] ? a << 7'd1  : a; 
	genvar i;
	generate
		for (i=1; i<S; i=i+1)begin:loop_blk
			assign tmp[i] = b[i] ? tmp[i-1] << 2**i : tmp[i-1];
		end
	endgenerate
	assign c = tmp[S-1];
endmodule

module LOD_N (in, out);
	function [31:0] log2;
		input reg [31:0] value;
		begin
			value = value-1;
			for (log2=0; value>0; log2=log2+1)
				value = value>>1;
		end
	endfunction

	parameter N = 64;
	localparam S = log2(N); 
	input [N-1:0] in;
	output [S-1:0] out;

	wire vld;
	LOD #(.N(N)) l1 (in, out, vld);
endmodule

module LOD (in, out, vld);
	function [31:0] log2;
		input reg [31:0] value;
		begin
			value = value-1;
			for (log2=0; value>0; log2=log2+1)
				value = value>>1;
		end
	endfunction

	parameter N = 64;
	localparam S = log2(N);

	input [N-1:0] in;
	output [S-1:0] out;
	output vld;

	generate
		if (N == 2) begin
			assign vld = |in;
			assign out = ~in[1] & in[0];
		end
		else if (N & (N-1))
			//LOD #(1<<S) LOD ({1<<S {1'b0}} | in,out,vld);
			LOD #(1<<S) LOD ({in,{((1<<S) - N) {1'b0}}},out,vld);
		else begin
			wire [S-2:0] out_l, out_h;
			wire out_vl, out_vh;
			
			LOD #(N>>1) l(in[(N>>1)-1:0],out_l,out_vl);
			LOD #(N>>1) h(in[N-1:N>>1],out_h,out_vh);
			assign vld = out_vl | out_vh;
			assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
		end
	endgenerate
endmodule
