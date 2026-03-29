/* -------------------------------------------------------------------------- */
/*                                  16位浮点数加法                                  */
/* -------------------------------------------------------------------------- */
module ADD#(
	parameter INFO_WIDTH = 23
)(
	input [INFO_WIDTH-1:0]    info_in  , 
	output [INFO_WIDTH-1:0]   info_out , 

	input           		  in_vld   , 
	output					  out_vld  ,

	input [15:0]			  data0    , 
	input [15:0]    		  data1    , 
	output [15:0]			  sum
);
	assign out_vld = in_vld;
	assign info_out = info_in;

	FLOAT16_ADD U_FLOAT16_ADD(
        .floatA                 (data0    ),
        .floatB                 (data1    ),
        .sum                    (sum[15:0])
    );
endmodule