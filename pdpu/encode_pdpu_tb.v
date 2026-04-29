`timescale 1ns / 1ps

module encode_pdpu_tb;
	parameter N=8;
	parameter ES=2;
	localparam W = $clog2(N);	
	localparam FS=N-ES-1;
	reg sign;				// sign
	reg [FS-1:0] frac;
	wire [W+ES:0] exp;
	reg special;
	wire [N-1:0] out;

	encode_pdpu #(N, ES) u1 (sign, frac, exp, special, out);

	reg [ES-1:0] expl;
	reg signed [W:0] exph;

	initial begin
		$display("time : s frac exp expl out");
	//	$monitor("%10d : %b %b %b(%5d) : %b %b %b %b", $time, sign, frac, exp, exph, out, u1.tmp_o, u1.r_o, u1.tmp1_o_rnd);
		$monitor("%10d : %b %b %b(%5d) : %b", $time, sign, frac, exp, exph, out);
		#2500
		$stop;
	end


	assign exp = {exph, expl};

	integer i;
/*
	initial begin
		sign = 1'b0;
		special = 1'b0;
//		frac = 5'b11010;
		frac = 5'b01010;
//		frac = 5'b01110;
		expl = 2'b11;
		exph = 4'b0000;
		for (i=1; i<16; i=i+1) begin
			#50 exph = i;
		end
	end
*/

	initial begin
		sign = 1'b0;
		special = 1'b0;
		frac = 5'b11010;
		expl = 2'b11;
		exph = 4'b0000;
		for (i=1; i<16; i=i+1) begin
			#50 exph = i;
		end
		$display(" ");
		frac = 5'b01010;
		expl = 2'b11;
		exph = 4'b0000;
		for (i=1; i<16; i=i+1) begin
			#50 exph = i;
		end
		$display(" ");
		frac = 5'b100000;
		expl = 2'b11;
		exph = 4'b0000;
		for (i=1; i<16; i=i+1) begin
			#50 exph = i;
		end
	end
endmodule
