module DIVISION_FLOAT16#(
	parameter DATA_WIDTH = 16
)(
	input clk                      , 
	input rst_n                    , 
	input in_vld                   , 
	input [DATA_WIDTH-1:0]dividend , 
	input [DATA_WIDTH-1:0]divider  , 
	output reg out_vld             , 
	output reg [DATA_WIDTH-1:0]result
);
	
	wire       signa                           ;
    wire       signb                           ;
    wire       signc                           ;
    wire  [4:0]expa                            ;
    wire  [4:0]expb                            ;
    wire  [10:0]fraca                          ;
    wire  [10:0]fracb                          ;
    wire  [10:0]fracc                          ;
    wire signed[5:0]quotient                   ;
	wire [5:0]quotient_add15;
	wire [5:0]quotient_sub1;
	
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			out_vld <= 1'b0;
		end
		else begin
			out_vld <= in_vld;
		end
	end
	
	assign {signa,expa,fraca[9:0]} = dividend;
	assign {signb,expb,fracb[9:0]} = divider;

	assign fraca[10]=1;
	assign fracb[10]=1;
	assign signc = signa^signb;
	assign quotient = {1'b0,expa}-{1'b0,expb};
	assign quotient_add15 = quotient+6'h0f;
	assign quotient_sub1 = quotient_add15 - 6'h01;
	assign fracc = fraca/fracb;

	always@(posedge clk)begin
		if(in_vld)begin
			if(dividend == 0 || divider == 0)begin
				if(dividend == 0)begin
					result <= dividend;
				end
				else begin
					result <= 16'hffff;
				end
			end
			else begin
				if(fracc[10])begin
					result <= {signc,quotient_add15[4:0],fracc[9:0]};
				end
				else begin
					result <= {signc,quotient_sub1[4:0],fracc[9:0]};
				end
			end
		end
	end
endmodule