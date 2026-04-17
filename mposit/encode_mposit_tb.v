// Testbench for encode_mposit 

`timescale 1ns / 1ps

module encode_mposit_tb;
	parameter N=8;
	parameter ES=2;
	localparam W = $clog2(N);	
	localparam FS=N-ES-1;
	reg sign;				// sign
	reg [FS-1:0] frac;
	wire [W+ES:0] exp;
	reg special;
	wire [N-1:0] out;
	wire ovf;

	reg [ES-1:0] expl;
	reg signed [W:0] exph;

	encode_mposit #(N, ES) u1 (sign, frac, exp, special, out);

	initial begin
		$display(" time : s frac  exp         : out      c : mk1     mk2       mask    mk1o    mk2s");
		$monitor("%5d : %b %b %b(%3d) : %b %b : %b %b %b %b %b", $time, 
			sign, frac, exp, exph, out, u1.carry
			, u1.mk1, u1.mk2, u1.mask, u1.mk1_o, u1.mk2_s);
		#3000
		$stop;
	end

	assign exp = {exph, expl};

	integer i;

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
