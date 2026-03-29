/* -------------------------------------------------------------------------- */
/*                                  16位浮点数乘法                                  */
/* -------------------------------------------------------------------------- */
module MUL(
	input		clk      , 
	input		rst_n	 ,
	
	input		vld_in   , 
	output reg  vld_out  , 

	input [22:0]info_in  , // 输入信息（23位）
	output reg [23:0]info_out, // 输出信息（24位）

	input [15:0]data0    ,
	input [15:0]data1    ,
	output reg [15:0]mul
);

	wire [15:0]mul_result;

	/* --------------------------------- vld_out -------------------------------- */
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            vld_out <= 1'd0;
        end
        else begin
            vld_out <= vld_in;
        end
    end

    /* -------------------------------- info_out -------------------------------- */
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
            info_out <= 'd0;
		end
		else if(vld_in)begin
            info_out <= info_in;
		end
		else begin
            info_out <= 'd0;
		end
	end

	/* ------------------------------- mul_result ------------------------------- */
	FLOAT16_MUL U_X3_DIV_FACT3(
        .floatA                 (data0       ),
        .floatB                 (data1       ),
        .product                (mul_result  ) 
    );

	/* ----------------------------------- mul ---------------------------------- */
    always@(posedge clk)begin
        if(vld_in)begin
            mul <= mul_result;
        end
	end
endmodule