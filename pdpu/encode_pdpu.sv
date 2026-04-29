// PDPU posit encoder
// - based on posit_encoder of the following source codes
//		https://github.com/qleenju/PDPU/blob/main/sources/posit_encoder.sv

// Posit encoder
module encode_pdpu #(
    parameter int unsigned n = 32,
    parameter int unsigned es = 2,
    //parameter int unsigned nd = pdpu_pkg::clog2(n-1),
	parameter int unsigned nd = $clog2(n),
    parameter int unsigned EXP_WIDTH = nd+es,       // not include sign bit
    parameter int unsigned MANT_WIDTH = n-es-3      // not include implicit bit
) (
    input logic sign_i,
	//input logic [MANT_WIDTH:0] mant_norm_i,
	input logic [MANT_WIDTH-1:0] fraction,			// added
	input logic signed [EXP_WIDTH:0] rg_exp_i,
    input logic special,		// added
    output logic [n-1:0] result_o
);
	// added
	logic [MANT_WIDTH:0] mant_norm_i;
	assign mant_norm_i[MANT_WIDTH] = ~special;
	assign mant_norm_i[MANT_WIDTH-1:0] = fraction;
	
    // ---------------
    // Determine whether input is effective 0
    // ---------------
    logic input_not_zero;
    assign input_not_zero = mant_norm_i[MANT_WIDTH];

    // ---------------
    // Compute regime_k and exp
    // ---------------
    logic signed [EXP_WIDTH-es:0] regime_k;
    logic signed [es:0] exp;

    assign regime_k = rg_exp_i[EXP_WIDTH:es];
    assign exp = rg_exp_i[es-1:0];

    // ---------------
    // initial regime field
    // ---------------
    logic sign_k;
    logic [n-2:0] rg_const;
    logic [n-2:0] regime;
    
    assign sign_k = rg_exp_i[EXP_WIDTH];
    assign rg_const = 1;
    assign regime = sign_k ? rg_const : ~rg_const;

    // ---------------
    // Compute regime bits
    // ---------------
    logic [EXP_WIDTH-es:0] regime_bits;
    
    assign regime_bits = sign_k ? (~regime_k+2) : (regime_k+2);
    
    // ---------------
    // Combine {regime, Exp, Mantissa}
    // ---------------
    localparam int unsigned TEMP_WIDTH = (n-1)+es+MANT_WIDTH;   // regime + exponent + mantissa
    logic [TEMP_WIDTH-1:0] rg_exp_mant;

    assign rg_exp_mant = {regime, exp[es-1:0], mant_norm_i[MANT_WIDTH-1:0]}; 
    
    // ---------------
    // Calculate amount of right shift
    // ---------------
    localparam int unsigned MAX_SHIFT_AMOUNT = MANT_WIDTH + es + 1;
//    localparam int unsigned SHIFT_WIDTH = pdpu_pkg::clog2(MAX_SHIFT_AMOUNT+1);
    localparam int unsigned SHIFT_WIDTH = $clog2(MAX_SHIFT_AMOUNT);
    logic [SHIFT_WIDTH-1:0] shift_amount;
    
    assign shift_amount = (regime_bits>=n) ? MAX_SHIFT_AMOUNT : (regime_bits+(MANT_WIDTH+es-n+1));

    // ---------------
    // Right Shift
    // ---------------
    logic [TEMP_WIDTH+MAX_SHIFT_AMOUNT-1:0] value_before_shift, value_after_shift;
    
    assign value_before_shift = rg_exp_mant << MAX_SHIFT_AMOUNT;
    barrel_shifter #(
        .WIDTH(TEMP_WIDTH+MAX_SHIFT_AMOUNT),
        .SHIFT_WIDTH(SHIFT_WIDTH),
        .MODE(1'b1)
    ) u_barrel_shifter(
        .operand_i(value_before_shift),
        .shift_amount(shift_amount),
        .result_o(value_after_shift)
    );

    // ---------------
    // Compute abs_value and rounding_bits
    // ---------------
    logic [n-2:0] value_before_round;
    logic [MAX_SHIFT_AMOUNT-1:0] rounding_bits;

    assign {value_before_round,rounding_bits} = value_after_shift[MAX_SHIFT_AMOUNT+n-2:0];

    // ---------------
    // Perform rounding (RNE mode is applied by default)
    // ---------------
    logic round_bit;
    logic sticky_bit;
    logic round_value;
    logic [n-2:0] value_after_round;

    assign round_bit = rounding_bits[MAX_SHIFT_AMOUNT-1];
    assign sticky_bit = |rounding_bits[MAX_SHIFT_AMOUNT-2:0];
    assign round_value = round_bit & (sticky_bit | value_before_round[0]);
    assign value_after_round = value_before_round + round_value;

    // ---------------
    // Output result
    // ---------------
    logic [n-1:0] normal_result;
    assign normal_result = sign_i ? {1'b1,~value_after_round+1} : {1'b0,value_after_round};
    assign result_o = input_not_zero ? normal_result : '0;

endmodule