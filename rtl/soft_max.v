// 允许分子和分母使用不同的数据 有啥用待确定
module SOFT_MAX#(
	parameter DATA_WIDTH = 16,    // 数据位宽，默认为16位浮点数
	parameter DATA_NUM = 4,       // 输入数据数量，默认为4
	parameter INFO_WIDTH = 20     // 信息位宽，默认为20位
)(
	input									clk               , 
	input									rst_n             , 
    
	input                           		sum_clear         , // 清除累加和的信号
    
	input [INFO_WIDTH-1:0]				    soft_max_info_in  , // 输入的Softmax控制信息
	output reg [INFO_WIDTH-1:0]				soft_max_info_out , // 输出的Softmax控制信息

	input                           		denomintor_in_vld , // 分母输入有效信号
	input                           		numerator_in_vld  , // 分子输入有效信号
    input [DATA_NUM*DATA_WIDTH-1:0] 		denomintor_in     , // 分母输入数据，4个16位浮点数
	input [DATA_NUM*DATA_WIDTH-1:0] 		numerator_in      , // 分子输入数据，4个16位浮点数
	output reg                              denomintor_sum_ok , // 分母求和完成信号
	output     [DATA_NUM*DATA_WIDTH-1:0]    data_out          , // 输出数据，4个16位浮点数
	output									out_vld             // 输出有效信号
);	

    // 内部信号定义
    reg  [DATA_WIDTH-1:0]       denomintor_sum                  ; // 分母累加和寄存器

    // 各种有效信号
    wire                                 exp_in_vld             ; // 指数计算输入有效
    wire                                 exp_out_vld            ; // 指数计算输出有效
    wire                                 sum0_vld               ; // 第一次加法有效
    wire [15:0]                          sum0                   ; // 第一次加法结果
    wire                                 sum1_vld               ; // 第二次加法有效
    wire [15:0]                          sum1                   ; // 第二次加法结果
    wire                                 sum2_in_vld            ; // 第三次加法输入有效
    wire                                 sum2_vld               ; // 第三次加法输出有效
    wire [15:0]                          sum2                   ; // 第三次加法结果
    wire                                 result_vld0            ; // 除法结果有效

    // 指数计算相关的数据信号
    wire [DATA_NUM*DATA_WIDTH-1:0]exp_in;      // 指数计算输入
    wire [DATA_NUM*DATA_WIDTH-1:0]exp;         // 指数计算结果
    wire [DATA_NUM*DATA_WIDTH-1:0]exp_denomintor_in; // 分母的指数结果
    wire [DATA_NUM*DATA_WIDTH-1:0]exp_numerator_in;  // 分子的指数结果
	
	// 指数计算输入控制
	assign exp_in_vld = denomintor_in_vld|numerator_in_vld; // 任一输入有效时开始指数计算
	assign exp_in = denomintor_in_vld ? denomintor_in : numerator_in; // 选择输入数据
	
	// 生成4个指数计算模块，每个处理一个16位浮点数
	generate 
		genvar I;
		for(I = 0; I < DATA_NUM; I = I+1)begin:U
			EXP_FLOAT16 EXP(
				.clk                    (clk                                 ),
        		.rst_n                  (rst_n                               ),
        		.in_vld                 (exp_in_vld                          ),
        		.data_in                (exp_in[I*DATA_WIDTH+:DATA_WIDTH]    ),
        		.out_vld                (exp_out_vld                         ),
        		.exp                    (exp[I*DATA_WIDTH+:DATA_WIDTH]       )
		    );
		end
	endgenerate
	
	// 分配指数计算结果
	assign exp_denomintor_in= exp; // 分母的指数结果
	assign exp_numerator_in = exp;  // 分子的指数结果

	// 第一次加法：计算前两个数的和
	ADD U0_ADD(
        .info_in                (23'd0                                            ),
        .data0                  (exp_denomintor_in[DATA_WIDTH*1-1-:DATA_WIDTH]    ),
        .data1                  (exp_denomintor_in[DATA_WIDTH*2-1-:DATA_WIDTH]    ),
        .in_vld                 (denomintor_in_vld                                ),
        .out_vld                (sum0_vld                                         ),
        .info_out               (                                                 ),
        .sum                    (sum0                                             )
    );
	// 第二次加法：计算后两个数的和
	ADD U1_ADD(
        .info_in                (23'd0                                            ),
        .data0                  (exp_denomintor_in[DATA_WIDTH*3-1-:DATA_WIDTH]    ),
        .data1                  (exp_denomintor_in[DATA_WIDTH*4-1-:DATA_WIDTH]    ),
        .in_vld                 (denomintor_in_vld                                ),
        .out_vld                (sum1_vld                                         ),
        .info_out               (                                                 ),
        .sum                    (sum1                                             )
    );
	// 第三次加法：将前两次的结果相加
	assign sum2_in_vld = sum0_vld&sum1_vld; // 两次加法都完成时开始
	ADD U2_ADD(
        .info_in                (23'd0                          ),
        .data0                  (sum0                           ),
        .data1                  (sum1                           ),
        .in_vld                 (sum2_in_vld                    ),
        .out_vld                (sum2_vld                       ),
        .info_out               (                               ),
        .sum                    (sum2                           )
    );

	// 分母累加和寄存器控制逻辑
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			denomintor_sum <= {DATA_WIDTH{1'b0}}; // 复位时清零
		end
		else if(sum_clear)begin
			denomintor_sum <= {DATA_WIDTH{1'b0}}; // 清除信号有效时清零
		end
		else if(sum2_vld)begin
			denomintor_sum <= denomintor_sum+sum2; // 累加新的和
		end
	end

	// 分母求和完成信号控制逻辑
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			denomintor_sum_ok <= 1'b0; // 复位时清零
		end
		else if(sum2_vld&soft_max_info_in[15])begin
			denomintor_sum_ok <= 1'b1; // 求和完成且控制信号有效时置1
		end
		else begin
			denomintor_sum_ok <= 1'b0; // 其他情况清零
		end
	end

	// 四个除法器实例，分别计算每个概率值
	DIVISION_FLOAT16 #(.DATA_WIDTH(DATA_WIDTH)) U0_DIVISION_FLOAT16(
        .clk                    (clk                                             ),
        .rst_n                  (rst_n                                           ),
        .in_vld                 (numerator_in_vld                                ),
        .dividend               (exp_numerator_in[1*DATA_WIDTH-1-:DATA_WIDTH]    ),
        .divider                (denomintor_sum                                  ),
        .out_vld                (result_vld0                                     ),
        .result                 (data_out[1*DATA_WIDTH-1-:DATA_WIDTH]            )
    );
	DIVISION_FLOAT16 #(.DATA_WIDTH(DATA_WIDTH)) U1_DIVISION_FLOAT16(
        .clk                    (clk                                             ),
        .rst_n                  (rst_n                                           ),
        .in_vld                 (numerator_in_vld                                ),
        .dividend               (exp_numerator_in[2*DATA_WIDTH-1-:DATA_WIDTH]    ),
        .divider                (denomintor_sum                                  ),
        .out_vld                (                                                ),
        .result                 (data_out[2*DATA_WIDTH-1-:DATA_WIDTH]            )
    );
	DIVISION_FLOAT16 #(.DATA_WIDTH(DATA_WIDTH)) U2_DIVISION_FLOAT16(
        .clk                    (clk                                             ),
        .rst_n                  (rst_n                                           ),
        .in_vld                 (numerator_in_vld                                ),
        .dividend               (exp_numerator_in[3*DATA_WIDTH-1-:DATA_WIDTH]    ),
        .divider                (denomintor_sum                                  ),
        .out_vld                (                                                ),
        .result                 (data_out[3*DATA_WIDTH-1-:DATA_WIDTH]            )
    );
	DIVISION_FLOAT16 #(.DATA_WIDTH(DATA_WIDTH)) U3_DIVISION_FLOAT16(
        .clk                    (clk                                             ),
        .rst_n                  (rst_n                                           ),
        .in_vld                 (numerator_in_vld                                ),
        .dividend               (exp_numerator_in[4*DATA_WIDTH-1-:DATA_WIDTH]    ),
        .divider                (denomintor_sum                                  ),
        .out_vld                (                                                ),
        .result                 (data_out[4*DATA_WIDTH-1-:DATA_WIDTH]            )
    );

	// 输出有效信号控制
	assign out_vld = result_vld0; // 使用第一个除法器的输出有效信号

	// Softmax信息输出控制逻辑
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			soft_max_info_out <= 'd0; // 复位时清零
		end else if(denomintor_in_vld|numerator_in_vld)begin
			soft_max_info_out <= soft_max_info_in; // 输入有效时更新信息
		end
	end
endmodule