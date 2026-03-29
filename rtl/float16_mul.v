module FLOAT16_MUL
(
	input wire [15:0] floatA,
	input wire [15:0] floatB,
	output reg [15:0] product
);

	wire sign; // 输出的正负标志位
	wire signed [5:0] exponent; // 输出数据的指数，因为有正负所以选择有符号数
	reg signed [5:0] exponent_sft; // 输出数据的指数，因为有正负所以选择有符号数
	wire [9:0] mantissa; // 输出数据的小数
	wire [10:0] fractionA;//fraction = {1,mantissa} // 计算二进制数据最高位补1
	wire [10:0] fractionB;//fraction = {1,mantissa} // 计算二进制数据最高位补1
	wire [21:0] fraction; // 相乘结果参数
	reg [21:0] fraction_sft; // 相乘结果参数
	
	assign sign = floatA[15]^floatB[15]; // 异或门判断输出的计算正负
	
	assign exponent = floatA[14:10] + floatB[14:10] - 5'h0f; // 由于借位给fractionA和fractionB需要先补齐两位指数
	
	assign fractionA = {1'b1,floatA[9:0]}; //借位给fractionA
	assign fractionB = {1'b1,floatB[9:0]}; //借位给fractionB
	assign fraction = fractionA * fractionB; //计算二进制乘法
	assign mantissa = fraction_sft[21:12];// 按照半精度浮点数的格式输出
	
	always@(*)begin
		
	end
	always @(*)begin
		if(floatA == 0 || floatB == 0)begin// 处理乘数有一个或者两个均为0的情况
			product = 0;				//  输出为0
		end
		else if(exponent_sft[5]==1'b1) begin //太小了输出全0(精度问题)
			product=16'b0000000000000000;
		end
		else begin
			product = {sign,exponent_sft[4:0],mantissa}; //拼接输出数据
		end
	end

	always @ (*)begin
		// 找到第一个不为0的数字并对指数进行匹配处理
		case(1)
			fraction[21]:begin
				fraction_sft = fraction << 1;
				exponent_sft = exponent + 1; 
			end
			fraction[20]:begin
				fraction_sft = fraction << 2;
				exponent_sft = exponent + 0; 
			end
			fraction[19]:begin
				fraction_sft = fraction << 3;
				exponent_sft = exponent - 1; 
			end
			fraction[18]:begin
				fraction_sft = fraction << 4;
				exponent_sft = exponent - 2; 
			end
			fraction[17]:begin
				fraction_sft = fraction << 5;
				exponent_sft = exponent - 3; 
			end
			fraction[16]:begin
				fraction_sft = fraction << 6;
				exponent_sft = exponent - 4; 
			end
			fraction[15]:begin
				fraction_sft = fraction << 7;
				exponent_sft = exponent - 5; 
			end
			fraction[14]:begin
				fraction_sft = fraction << 8;
				exponent_sft = exponent - 6; 
			end
			fraction[13]:begin
				fraction_sft = fraction << 9;
				exponent_sft = exponent - 7; 
			end
			fraction[12]:begin
				fraction_sft = fraction << 10;
				exponent_sft = exponent - 8;
			end
			default:begin
				fraction_sft = fraction;
				exponent_sft = exponent;
			end
		endcase
	end
endmodule
