// 数据位宽：16位
// 注意力头数量：8个
// 数据并行度：每个时钟周期处理4个数据
module TRANSFORMER#(
	parameter DATA_WIDTH = 16,
	parameter HEADER_NUM = 8,
	parameter DATA_NUM   = 4
)(
	input                            clk                   ,
	input                            rst_n                 ,

	//X Channel 
	// 尺寸：4×16 = 64位
	// 每个时钟周期输入4个16位数据
	input                            x_ok                  ,
	output                           x_ren                 ,
	output							 x_cs                  ,
	output [12:0 ]                   x_rd_addr             ,
	input  [DATA_NUM*DATA_WIDTH-1:0] x                     ,

	//Q/K/V通道
	// 权重数据：8×8×16 = 1024位（每个头8个16位数据）
	// 位图：8×16 = 128位（每个头16位位图）
	/* -------------------------------------------------------------------------- */
	input  [HEADER_NUM-1:0]                     wq_ok      , 
	output [HEADER_NUM-1:0]                     wq_ren     , 
	output [HEADER_NUM-1:0]						wq_cs      , 
	output [HEADER_NUM*11-1:0 ]                 wq_rd_addr , 
	input  [HEADER_NUM*8*DATA_WIDTH-1:0]		wq         ,
	input  [HEADER_NUM*16-1:0]					wq_bit_map ,
	/* -------------------------------------------------------------------------- */
	input  [HEADER_NUM-1:0]                     wk_ok         , 
	output [HEADER_NUM-1:0]                     wk_ren        , 
	output [HEADER_NUM-1:0]				        wk_cs         , 
	output [HEADER_NUM*11-1:0 ]                 wk_rd_addr    , 
	input  [HEADER_NUM*8*DATA_WIDTH-1:0]		wk            , 
	input  [16*HEADER_NUM-1:0]					wk_bit_map	  , 
    /* -------------------------------------------------------------------------- */
	input  [HEADER_NUM-1:0]                     wv_ok         , 
	output [HEADER_NUM-1:0]                     wv_ren        , 
	output [HEADER_NUM-1:0]			            wv_cs         , 
	output [HEADER_NUM*11-1:0]                  wv_rd_addr    , 
	input  [HEADER_NUM*8*DATA_WIDTH-1:0]		wv            , 
	input  [HEADER_NUM*16-1:0]					wv_bit_map    , 
    
	//OUTPUT
	// 尺寸：64×64×16 = 65536位
	// 每个注意力头输出一个64×64的矩阵，每个元素16位
	output                       attention_vld,
	output [64*64*DATA_WIDTH-1:0]attention0  ,
	output [64*64*DATA_WIDTH-1:0]attention1  ,
	output [64*64*DATA_WIDTH-1:0]attention2  ,
	output [64*64*DATA_WIDTH-1:0]attention3  ,
	output [64*64*DATA_WIDTH-1:0]attention4  ,
	output [64*64*DATA_WIDTH-1:0]attention5  ,
	output [64*64*DATA_WIDTH-1:0]attention6  ,
	output [64*64*DATA_WIDTH-1:0]attention7   
);
	genvar I;

	// 输入矩阵(X)：512×64
	// 权重矩阵(Q/K/V)：64×512
    localparam X_MAT_W = 512 ; 
    localparam X_MAT_H = 64  ; 
    localparam W_MAT_W = 64  ; 
    localparam W_MAT_H = 512 ; 

    wire [64*64*DATA_WIDTH-1:0]attention[HEADER_NUM-1:0];
	
	generate 
		for(I = 0; I < 8; I = I+1)begin:HEAD
			if(I == 0)begin
				HEAD#(
        			.DATA_NUM  (DATA_NUM  ), 
        			.X_MAT_W   (X_MAT_W   ), 
        			.X_MAT_H   (X_MAT_H   ), 
        			.W_MAT_W   (W_MAT_W   ), 
        			.W_MAT_H   (W_MAT_H   ), 
        			.DATA_WIDTH(DATA_WIDTH)
        		)U_HEAD(
        			.clk        (clk  ), 
        			.rst_n      (rst_n), 
        		
        			//X Channel
        			.x_ok       (x_ok     ) ,
        			.x_ren      (x_ren    ) ,
        			.x_cs       (x_cs     ) ,
        			.x_rd_addr  (x_rd_addr) ,
        			.x          (x        ) ,
        		
        			//Q Channel
        			.wq_ok      (wq_ok     [I]                                          ), 
        			.wq_ren     (wq_ren    [I]                                          ), 
        			.wq_cs      (wq_cs     [I]                                          ), 
        			.wq_rd_addr (wq_rd_addr[I*11+:11]                                   ), 
        			.wq         (wq        [I*8*DATA_WIDTH+:8*DATA_WIDTH]               ), 
					.wq_bit_map (wq_bit_map[I*16+:16]                                   ),
        		    
        			//K Channel
        			.wk_ok      (wk_ok     [I]                                          ), 
        			.wk_ren     (wk_ren    [I]                                          ), 
        			.wk_cs      (wk_cs     [I]								            ), 
        			.wk_rd_addr (wk_rd_addr[I*11+:11]                                   ), 
        			.wk         (wk        [I*8*DATA_WIDTH+:8*DATA_WIDTH]               ), 
					.wk_bit_map (wk_bit_map[I*16+:16]),
        		    
        			//V Channel
        			.wv_ok      (wv_ok     [I]                                          ), 
        			.wv_ren     (wv_ren    [I]                                          ), 
        			.wv_cs      (wv_cs     [I]                                          ), 
        			.wv_rd_addr (wv_rd_addr[I*11+:11]                                   ), 
        			.wv         (wv        [I*8*DATA_WIDTH+:8*DATA_WIDTH]               ), 
					.wv_bit_map (wv_bit_map[I*16+:16]),
					
					.attention_vld(attention_vld),
        			.attention(attention[I])
        		);
			end else begin
				HEAD#(
        			.DATA_NUM  (DATA_NUM  ), 
        			.X_MAT_W   (X_MAT_W   ), 
        			.X_MAT_H   (X_MAT_H   ), 
        			.W_MAT_W   (W_MAT_W   ), 
        			.W_MAT_H   (W_MAT_H   ), 
        			.DATA_WIDTH(DATA_WIDTH)
        		)U_HEAD(
        			.clk        (clk  ), 
        			.rst_n      (rst_n), 
        		
        			//X Channel
        			.x_ok       (x_ok     ) ,
        			.x_ren      (         ) ,
        			.x_cs       (         ) ,
        			.x_rd_addr  (         ) ,
        			.x          (x        ) ,
        		
        			//Q Channel
        			.wq_ok      (wq_ok     [I]                                          ), 
        			.wq_ren     (wq_ren    [I]                                          ), 
        			.wq_cs      (wq_cs     [I]                                          ), 
        			.wq_rd_addr (wq_rd_addr[I*11+:11]                                   ), 
        			.wq         (wq        [I*8*DATA_WIDTH+:8*DATA_WIDTH]               ), 
					.wq_bit_map (wq_bit_map[I*16+:16]),
        		    
        			//K Channel
        			.wk_ok      (wk_ok     [I]                                          ), 
        			.wk_ren     (wk_ren    [I]                                          ), 
        			.wk_cs      (wk_cs     [I]								            ), 
        			.wk_rd_addr (wk_rd_addr[I*11+:11]                                   ), 
        			.wk         (wk        [I*8*DATA_WIDTH+:8*DATA_WIDTH]               ), 
					.wk_bit_map (wk_bit_map[I*16+:16]),
        		    
        			//V Channel
        			.wv_ok      (wv_ok     [I]                                          ), 
        			.wv_ren     (wv_ren    [I]                                          ), 
        			.wv_cs      (wv_cs     [I]                                   ), 
        			.wv_rd_addr (wv_rd_addr[I*11+:11]                                     ), 
        			.wv         (wv        [I*8*DATA_WIDTH+:8*DATA_WIDTH] ), 
					.wv_bit_map (wv_bit_map[I*16+:16]),
        		
					.attention_vld(),
        			.attention  (attention[I])
        		);
			end
		end
	endgenerate
    
    assign attention0 = attention[0];
    assign attention1 = attention[1];
    assign attention2 = attention[2];
    assign attention3 = attention[3];
    assign attention4 = attention[4];
    assign attention5 = attention[5];
    assign attention6 = attention[6];
    assign attention7 = attention[7];
endmodule

