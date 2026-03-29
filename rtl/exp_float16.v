module EXP_FLOAT16#(
	parameter DATA_WIDTH=16
)(
	input                   clk     , 
	input                   rst_n   , 

	input                   in_vld  , 
	output					out_vld , 

	input [DATA_WIDTH-1:0]  data_in , 
	output [DATA_WIDTH-1:0] exp
);
    parameter ONE   = 16'h3c00;//1/1
    parameter FACT2 = 16'b0_01110_0000000000;// 1/2!
    parameter FACT3 = 16'b0_01100_0101010101;// 1/3!
    parameter FACT4 = 16'b0_01010_0101010101;// 1/4!
    parameter FACT5 = 16'b0_01000_0001000100;// 1/5!

    wire [15:0]                 x                               ;
    wire [15:0]                 x2                              ;
    wire [15:0]                 x3                              ;
    wire [15:0]                 x4                              ;
    wire [15:0]                 x5                              ;
    wire [15:0]                 fact2                           ;
    wire [15:0]                 x2_div_fact2                    ;
    wire [15:0]                 fact3                           ;
    wire [15:0]                 x3_div_fact3                    ;
    wire [15:0]                 fact4                           ;
    wire [15:0]                 x4_div_fact4                    ;
    wire [15:0]                 fact5                           ;
    wire [15:0]                 x5_div_fact5                    ;
    wire [15:0]                 one                             ;
    wire [15:0]                 add_x1                          ;
    wire [15:0]                 add_x2                          ;
    wire [15:0]                 add_x3                          ;
    wire [15:0]                 add_x4                          ;
    wire [15:0]                 add_x5                          ; 

    assign out_vld = in_vld;
    assign exp = add_x5;
    assign x = data_in;

    /* -------------------------- 计算x的幂：x², x³, x⁴, x⁵ -------------------------- */
    FLOAT16_MUL U_X2(
        .floatA                 (x                              ),
        .floatB                 (x                              ),
        .product                (x2                             )
    );
    FLOAT16_MUL U_X3(
        .floatA                 (x                              ),
        .floatB                 (x2                             ),
        .product                (x3                             )
    );
    FLOAT16_MUL U_X4(
        .floatA                 (x                              ),
        .floatB                 (x3                             ),
        .product                (x4                             )
    );
    FLOAT16_MUL U_X5(
        .floatA                 (x                              ),
        .floatB                 (x4                             ),
        .product                (x5                             )
    );

    /* ---------------- 将各幂与对应的阶乘倒数相乘：x²/2!, x³/3!, x⁴/4!, x⁵/5! ---------------- */
    assign fact2=FACT2;
    FLOAT16_MUL U_X2_DIV_FACT2(
        .floatA                 (x2                             ),
        .floatB                 (fact2                          ),
        .product                (x2_div_fact2                   )
    );
    assign fact3=FACT3;
    FLOAT16_MUL U_X3_DIV_FACT3(
        .floatA                 (x3                             ),
        .floatB                 (fact3                          ),
        .product                (x3_div_fact3                   )
    );
    assign fact4=FACT4;
    FLOAT16_MUL U_X4_DIV_FACT4(
        .floatA                 (x4                             ),
        .floatB                 (fact4                          ),
        .product                (x4_div_fact4                   )
    );
    assign fact5=FACT5;
    FLOAT16_MUL U_X5_DIV_FACT5(
        .floatA                 (x5                             ),
        .floatB                 (fact5                          ),
        .product                (x5_div_fact5                   )
    );

    /* --------------- 逐步累加所有项：1 + x + x²/2! + x³/3! + ... + x⁵/5! -------------- */
    assign one = ONE;
    FLOAT16_ADD U_ADD_X1_FACT1(
        .floatA                 (one                            ),
        .floatB                 (x                              ),
        .sum                    (add_x1                         )
    );
    FLOAT16_ADD U_ADD_X2_FACT1(
        .floatA                 (add_x1                         ),
        .floatB                 (x2_div_fact2                   ),
        .sum                    (add_x2                         )
    );
    FLOAT16_ADD U_ADD_X3_FACT1(
        .floatA                 (add_x2                         ),
        .floatB                 (x3_div_fact3                   ),
        .sum                    (add_x3                         )
    );
    FLOAT16_ADD U_ADD_X4_FACT1(
        .floatA                 (add_x3                         ),
        .floatB                 (x4_div_fact4                   ),
        .sum                    (add_x4                         )
    );
    FLOAT16_ADD U_ADD_X5_FACT1(
        .floatA                 (add_x4                         ),
        .floatB                 (x5_div_fact5                   ),
        .sum                    (add_x5                         )
    );
endmodule