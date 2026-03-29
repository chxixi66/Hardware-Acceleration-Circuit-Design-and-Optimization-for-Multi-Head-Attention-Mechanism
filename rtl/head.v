module HEAD#(
	parameter DATA_NUM       = 4   , 
	parameter X_MAT_W        = 512 , 
	parameter X_MAT_H        = 64  , 
	parameter W_MAT_W        = 64  , 
	parameter W_MAT_H        = 512 , 
	parameter DATA_WIDTH     = 161
)(
	input									clk        , 
	input                           		rst_n      , 

	//X Channel
	input									x_ok       , 
	output                          		x_ren      , 
	output									x_cs       , 
	output [12:0 ]                  		x_rd_addr  , // X通道读地址，13位宽
	input [DATA_NUM*DATA_WIDTH-1:0] 		x          , // X通道数据，宽度为 4*16

	//Q Channel
	input									wq_ok      , 
	output                          		wq_ren     , 
	output		                    		wq_cs      , 
	output [10:0 ]                  		wq_rd_addr , // Q通道读地址，11位宽
	input  [8*DATA_WIDTH-1:0]				wq         , // Q通道数据，宽度为8*16
	input  [15:0]							wq_bit_map , // Q通道位图，16位宽，控制数据有效性
    
	//K Channel
	input									wk_ok      , 
	output                          		wk_ren     , 
	output		                    		wk_cs      , 
	output [10:0 ]                  		wk_rd_addr , 
	input  [8*DATA_WIDTH-1:0]	    		wk         , 
	input  [15:0]							wk_bit_map , 
    
	//V Channel
	input									wv_ok      , 
	output                          		wv_ren     , 
	output		                    		wv_cs      , 
	output [10:0 ]                  		wv_rd_addr , 
	input  [8*DATA_WIDTH-1:0]				wv         , 
	input  [15:0]							wv_bit_map , 

	output reg                              attention_vld,
	output [W_MAT_W*X_MAT_H*DATA_WIDTH-1:0] attention     // 注意力结果，64*64*16bit = 65536位
);
	integer i;
	integer j;
	integer k;

	parameter IDEL                = 4'd0  ; // 空闲状态
	parameter CAL_QK              = 4'd1  ; // 计算Q*K
	parameter WAIT_QK_DLY         = 4'd2  ; // 等待Q*K计算完成
	parameter CAL_S               = 4'd3  ; // 计算Softmax
	parameter CAL_V               = 4'd4  ; // 计算V
	parameter WAIT_S_DLY          = 4'd5  ; // 等待Softmax完成
	parameter DENOMINTOR_SUM      = 4'd6  ; // 计算分母和
	parameter WAIT_DENOMINTOR_DLY = 4'd7  ; // 等待分母和计算完成
	parameter SOFT_MAX            = 4'd8  ; // Softmax计算
	parameter WAIT_SOFT_MAX_DLY   = 4'd9  ; // 等待Softmax完成
	parameter WAIT_AV_DONE        = 4'd10 ; // 等待Attention*V完成
	parameter ATTENTION           = 4'd11 ; // 计算最终Attention
	parameter WAIT_ATTENTION_DLY  = 4'd12 ; // 等待Attention计算完成

    /* --------------------------------- 通道控制信号 -------------------------------- */
    wire                              chn0_lmat_ok              ; // 通道0左矩阵数据有效信号
    wire                              chn0_lmat_cs              ; // 通道0左矩阵片选信号
    wire                              chn0_lmat_ren             ; // 通道0左矩阵读使能
    wire                              chn0_rmat_ok              ; // 通道0右矩阵数据有效信号
    wire                              chn0_rmat_cs              ; // 通道0右矩阵片选信号
    wire                              chn0_rmat_ren             ; // 通道0右矩阵读使能
    wire                              chn0_up_en                ; // 通道0更新使能
    wire                              chn0_mat_row_real_ok      ; // 通道0矩阵行数据有效信号
    wire                              chn0_mat_real_ok          ; // 通道0矩阵数据有效信号
    wire [3:0]                        chn0_state_c              ; // 通道0当前状态
    wire                              chn0_col_end              ; // 通道0列结束信号
    wire                              chn0_row_end              ; // 通道0行结束信号
    wire                              chn0_frm_end              ; // 通道0帧结束信号
    wire [6:0]                        chn0_lmat_col             ; // 通道0左矩阵列地址
    wire [6:0]                        chn0_lmat_row             ; // 通道0左矩阵行地址
    wire [6:0]                        chn0_rmat_col             ; // 通道0右矩阵列地址
    wire [6:0]                        chn0_rmat_row             ; // 通道0右矩阵行地址
    wire                              chn1_lmat_ok              ;
    wire                              chn1_lmat_cs              ;
    wire                              chn1_lmat_ren             ;
    wire                              chn1_rmat_ok              ;
    wire                              chn1_rmat_cs              ;
    wire                              chn1_rmat_ren             ;
    wire                              chn1_up_en                ;
    wire                              chn1_mat_real_ok          ;
    wire [3:0]                        chn1_state_c              ;
    wire                              chn1_col_end              ;
    wire                              chn1_row_end              ;
    wire                              chn1_frm_end              ;
    wire [6:0]                        chn1_lmat_col             ;
    wire [6:0]                        chn1_lmat_row             ;
    wire [6:0]                        chn1_rmat_col             ;
    wire [6:0]                        chn1_rmat_row             ;

	/* ---------------------------------- fifo ---------------------------------- */
	// FIFO数据 55bit
	// [54:51]: chn0_state_c(4位)
	// [50]: col_end(1位)
	// [49]: row_end(1位)
	// [48]: frm_end(1位)
	// [47:41]: col_base(7位)
	// [40:39]: col_offset(2位)
	// [38:32]: row_idx(7位)
	// [31:16]: rmat_data(16位)
	// [15:0]: lmat_data(16位)
    reg                         	  chn0_wr_en                ;
    wire [54:0]   					  chn0_din  				;
    wire                              chn0_full                 ;
    wire                              chn0_rd_en                ;
    wire [54:0]   					  chn0_dout 				;
    wire                              chn0_empty                ;
    reg                         	  chn1_wr_en                ;
	wire [54:0]   					  chn1_din  				;
    wire                              chn1_full                 ;
    wire                              chn1_rd_en                ;
    wire [54:0]   					  chn1_dout 				;
    wire                              chn1_empty                ;

	/* --------------------------------- softmax -------------------------------- */
	// 控制信息
    wire                              sum_clear                 ;
    wire                              denomintor_in_vld         ;
    wire                              numerator_in_vld          ;
    wire                              soft_max_vld              ;
    wire                              denomintor_sum_ok         ;
	// 输入/输出 4个x16bit = 64位
    wire [DATA_NUM*DATA_WIDTH-1:0]    denomintor_in             ;
    wire [DATA_NUM*DATA_WIDTH-1:0]    numerator_in              ;
    wire [DATA_NUM*DATA_WIDTH-1:0]    soft_max_data_out         ;
	// 信息
	// {chn0_state_c,chn0_row_end,chn0_frm_end,chn0_lmat_col,chn0_lmat_row};
    wire [SOFT_MAX_INFO_WIDTH-1:0]	  soft_max_info_in          ;
    wire [SOFT_MAX_INFO_WIDTH-1:0]	  soft_max_info_out         ;

    reg                         chn0_col_end_lock               ;
    reg                         chn0_row_end_lock               ;
    reg                         chn0_frm_end_lock               ;
    reg                         chn1_col_end_lock               ;
    reg                         chn1_row_end_lock               ;
    reg                         chn1_frm_end_lock               ;
    reg                         wv_ok_lock                      ;
    reg                         a_ok_lock                       ;
    reg  [3:0]                  chn0_cal_cnt                    ;
    reg  [3:0]                  chn1_cal_cnt                    ;

    /* --------------------------------- 乘法器和加法器 -------------------------------- */
    reg                         chn0_mul_vld_in                 ; 
    wire                        chn0_mul_vld                    ; // 通道0乘法结果有效信号
    wire [22:0]                 chn0_mul_info_out               ; // 通道0乘法器信息输出
    wire [15:0]                 chn0_mul                        ; // 通道0乘法结果
    reg                         chn1_mul_vld_in                 ;
    wire                        chn1_mul_vld                    ;
    wire [22:0]                 chn1_mul_info_out				;
    wire [15:0]                 chn1_mul                        ; 

    wire [15:0]                 chn0_add_data1                  ; // 通道0加法器输入1
    wire                        chn0_sum_vld                    ; // 通道0加法结果有效信号
    wire [22:0]   				chn0_sum_info_out		      	; // 通道0加法器信息输出
    wire [15:0]                 chn0_sum                        ; // 通道0加法结果
    wire [15:0]                 chn1_add_data1                  ;
    wire                        chn1_sum_vld                    ;
    wire [22:0]   				chn1_sum_info_out		      	;
    wire [15:0]                 chn1_sum                        ;


	/* ---------------------------------- 锁存器信号 --------------------------------- */
    // 左矩阵锁存器 4个×16bit = 64位
	// 存储从X通道读取的输入数据, 每个时钟周期可以锁存4个16位数据
	reg [DATA_NUM*DATA_WIDTH-1:0]chn0_lmat_lock;
	reg [DATA_NUM*DATA_WIDTH-1:0]chn1_lmat_lock;
	// 右矩阵锁存器 16个×16位 = 256位
	// 存储从Q/K/V通道读取的权重数据, 可以同时锁存16个16位数据
	reg [16*DATA_WIDTH-1:0]		chn0_rmat_lock; 
	reg [16*DATA_WIDTH-1:0]		chn1_rmat_lock; 
	// 位图锁存器 16位
	// 控制右矩阵数据的有效性, 每一位对应一个数据元素的有效性
	reg  [15:0]                 chn0_rmat_bit_map_lock          ;
    reg  [15:0]                 chn1_rmat_bit_map_lock          ;

	// 通道矩阵 64x64-16bit = 65536位
	// 用途: 存储QK和AttentionV的计算结果
	reg [DATA_WIDTH*W_MAT_W-1:0]chn0_mat[X_MAT_H-1:0];
	reg [DATA_WIDTH*W_MAT_W-1:0]chn1_mat[X_MAT_H-1:0];

	// 临时行数据
	// 尺寸: 64-16bit = 1024位
	// 用途: 临时存储一行的计算结果，用于累加
	reg [DATA_WIDTH*W_MAT_W-1:0]chn0_mat_oneline_tmp;
	reg [DATA_WIDTH*W_MAT_W-1:0]chn1_mat_oneline_tmp;

	/* --------------------------------- X通道控制信号 -------------------------------- */
	// X通道片选信号
	assign x_cs = chn0_state_c == CAL_QK ? chn0_lmat_cs :      // Q*K计算时使用chn0
				chn1_state_c == CAL_V  ? chn1_lmat_cs : 1'b0; // V计算时使用chn1

	// X通道读使能信号
	assign x_ren = chn0_state_c == CAL_QK ? chn0_lmat_ren :    // Q*K计算时使用chn0
				chn1_state_c == CAL_V  ? chn1_lmat_ren : 1'b0; // V计算时使用chn1

	// X通道读地址计算
	assign x_rd_addr = chn0_lmat_row*128+chn0_lmat_col;  // 行地址*128 + 列地址

	/* -------------------------------- Q权重矩阵控制信号 ------------------------------- */
	// Q矩阵片选信号
	assign wq_cs = chn0_state_c == CAL_QK ? chn0_rmat_cs : 1'b0;  // 只在Q*K计算时有效

	// Q矩阵读使能信号
	assign wq_ren = chn0_state_c == CAL_QK ? chn0_rmat_ren : 1'b0;

	// Q矩阵读地址计算
	assign wq_rd_addr = chn0_rmat_col*128+chn0_rmat_row;  // 列地址*128 + 行地址
	/* -------------------------------- K权重矩阵控制信号 ------------------------------- */
	// K矩阵片选信号
	assign wk_cs = chn1_state_c == CAL_QK ? chn1_rmat_cs : 1'b0;  // 只在Q*K计算时有效

	// K矩阵读使能信号
	assign wk_ren = chn1_state_c == CAL_QK ? chn1_rmat_ren : 1'b0;

	// K矩阵读地址与Q矩阵相同
	assign wk_rd_addr = wq_rd_addr;  // 复用Q矩阵的地址
	/* -------------------------------- V权重矩阵控制信号 ------------------------------- */
	// V矩阵片选信号
	assign wv_cs = chn1_state_c == CAL_V ? chn1_rmat_cs : 1'b0;  // 只在V计算时有效

	// V矩阵读使能信号
	assign wv_ren = chn1_state_c == CAL_V ? chn1_rmat_ren : 1'b0;

	// V矩阵读地址计算
	assign wv_rd_addr = chn1_rmat_col*128+chn1_rmat_row;  // 列地址*128 + 行地址

	/* -------------------------------- 数据有效性控制信号 ------------------------------- */
	// chn0左矩阵数据有效信号
	assign chn0_lmat_ok = chn0_state_c == IDEL ? x_ok :  // 空闲状态时检查输入有效
						chn0_state_c == WAIT_QK_DLY ? chn0_sum_vld&chn0_sum_info_out[16] :  // Q*K计算等待
						chn0_state_c == WAIT_S_DLY ? chn0_sum_vld&chn0_sum_info_out[16] : 1'b0;  // Softmax等待

	// chn0右矩阵数据有效信号
	assign chn0_rmat_ok = chn0_state_c == IDEL ? wq_ok :  // 空闲状态时检查Q矩阵有效
						chn1_state_c == WAIT_QK_DLY ? chn1_sum_vld&chn1_sum_info_out[16] :  // Q*K计算等待
						chn0_state_c == WAIT_S_DLY ? chn0_sum_vld&chn0_sum_info_out[16] : 1'b0;  // Softmax等待

	// chn1左矩阵数据有效信号
	assign chn1_lmat_ok = chn1_state_c == IDEL ? x_ok :  // 空闲状态时检查输入有效
						chn0_state_c == CAL_S ? chn0_frm_end&chn0_lmat_cs :  // Softmax计算时
						chn0_state_c == WAIT_SOFT_MAX_DLY ? soft_max_vld&soft_max_info_out[14] : 1'b0;  // Softmax等待

	// chn1右矩阵数据有效信号
	assign chn1_rmat_ok = chn1_state_c == IDEL ? wk_ok :  // 空闲状态时检查K矩阵有效
						chn1_state_c == CAL_S ? wv_ok_lock :  // V计算时
						chn1_state_c == WAIT_AV_DONE ? chn1_sum_vld&chn1_sum_info_out[16] : 1'b0;  // Attention*V等待

	/* -------------------------------- 行数据有效性控制 -------------------------------- */
	// chn0矩阵行数据有效信号
	assign chn0_mat_row_real_ok = (soft_max_vld|denomintor_sum_ok)&soft_max_info_out[15];

	TRANSFORMER_CTRL #(
        .X_MAT_W                (X_MAT_W                        ),
        .X_MAT_H                (X_MAT_H                        ),
        .W_MAT_W                (W_MAT_W                        ),
        .W_MAT_H                (W_MAT_H                        ),
        .IDEL                   (IDEL                           ),
        .CAL_QK                 (CAL_QK                         ),
        .WAIT_QK_DLY            (WAIT_QK_DLY                    ),
        .CAL_S                  (CAL_S                          ),
        .CAL_V                  (CAL_V                          ),
        .WAIT_S_DLY             (WAIT_S_DLY                     ),
        .DENOMINTOR_SUM         (DENOMINTOR_SUM                 ), // PARA_NEW
        .WAIT_DENOMINTOR_DLY    (WAIT_DENOMINTOR_DLY            ),
        .SOFT_MAX               (SOFT_MAX                       ),
        .WAIT_SOFT_MAX_DLY      (WAIT_SOFT_MAX_DLY              ), // PARA_NEW
        .WAIT_AV_DONE           (WAIT_AV_DONE                   ),
        .ATTENTION              (ATTENTION                      ),
        .WAIT_ATTENTION_DLY     (WAIT_ATTENTION_DLY             ) 
    )
    U_TRANSFORMER_CTRL(
        .clk                     (clk                           ), //input
        .rst_n                   (rst_n                         ), //input
        //Channel0
        .chn0_lmat_ok            (chn0_lmat_ok                  ), //input
        .chn0_lmat_cs            (chn0_lmat_cs                  ), //output
        .chn0_lmat_ren           (chn0_lmat_ren                 ), //output
        .chn0_rmat_ok            (chn0_rmat_ok                  ), //input
        .chn0_rmat_cs            (chn0_rmat_cs                  ), //output
        .chn0_rmat_ren           (chn0_rmat_ren                 ), //output
        .chn0_up_en              (chn0_up_en                    ), //input
        .chn0_mat_row_real_ok    (chn0_mat_row_real_ok          ), //input
        .chn0_mat_real_ok        (chn0_mat_real_ok              ), //input
        .chn0_state_c            (chn0_state_c[3:0]             ), //output
        .chn0_col_end            (chn0_col_end                  ), //output
        .chn0_row_end            (chn0_row_end                  ), //output
        .chn0_frm_end            (chn0_frm_end                  ), //output
        .chn0_lmat_col           (chn0_lmat_col[6:0]            ), //output
        .chn0_lmat_row           (chn0_lmat_row[6:0]            ), //output
        .chn0_rmat_col           (chn0_rmat_col[6:0]            ), //output
        .chn0_rmat_row           (chn0_rmat_row[6:0]            ), //output
        //Channel1
        .chn1_lmat_ok            (chn1_lmat_ok                  ), //input
        .chn1_lmat_cs            (chn1_lmat_cs                  ), //output
        .chn1_lmat_ren           (chn1_lmat_ren                 ), //output
        .chn1_rmat_ok            (chn1_rmat_ok                  ), //input
        .chn1_rmat_cs            (chn1_rmat_cs                  ), //output
        .chn1_rmat_ren           (chn1_rmat_ren                 ), //output
        .chn1_up_en              (chn1_up_en                    ), //input
        .chn1_mat_real_ok        (chn1_mat_real_ok              ), //input
        .chn1_state_c            (chn1_state_c[3:0]             ), //output
        .chn1_col_end            (chn1_col_end                  ), //output
        .chn1_row_end            (chn1_row_end                  ), //output
        .chn1_frm_end            (chn1_frm_end                  ), //output
        .chn1_lmat_col           (chn1_lmat_col[6:0]            ), //output
        .chn1_lmat_row           (chn1_lmat_row[6:0]            ), //output
        .chn1_rmat_col           (chn1_rmat_col[6:0]            ), //output
        .chn1_rmat_row           (chn1_rmat_row[6:0]            )  //output
    );
	

	always@(posedge clk)begin
		case(chn0_state_c)
			CAL_QK:begin
				if(x_cs&x_ren)begin
					chn0_lmat_lock <= x;
				end else if(chn0_wr_en&~chn0_full)begin
					chn0_lmat_lock <= {chn0_lmat_lock[DATA_WIDTH-1:0],chn0_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			WAIT_QK_DLY,WAIT_S_DLY:begin
				if(chn0_wr_en&~chn0_full)begin
					chn0_lmat_lock <= {chn0_lmat_lock[DATA_WIDTH-1:0],chn0_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			CAL_S:begin
				if(chn0_lmat_cs&chn0_lmat_ren)begin
					chn0_lmat_lock <= chn0_mat[chn0_lmat_row][chn0_lmat_col*DATA_NUM*DATA_WIDTH+:DATA_NUM*DATA_WIDTH];
				end
				else if(chn0_wr_en&~chn0_full)begin
					chn0_lmat_lock <= {chn0_lmat_lock[DATA_WIDTH-1:0],chn0_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
		endcase
	end

	always@(posedge clk)begin
		case(chn0_state_c)
			CAL_QK:begin
				if(wq_cs&wq_ren)begin
					chn0_rmat_lock <= {{(8*DATA_WIDTH){1'b0}},wq};
				end
				else if(chn0_wr_en&~chn0_full&chn0_rmat_bit_map_lock[0])begin
					chn0_rmat_lock <= {{(8*DATA_WIDTH){1'b0}},chn0_rmat_lock[DATA_WIDTH-1:0],chn0_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			WAIT_QK_DLY:begin
				if(chn0_wr_en&~chn0_full&chn0_rmat_bit_map_lock[0])begin
					chn0_rmat_lock <= {{(8*DATA_WIDTH){1'b0}},chn0_rmat_lock[DATA_WIDTH-1:0],chn0_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			CAL_S:begin
				if(chn0_lmat_cs&chn0_lmat_ren)begin
					chn0_rmat_lock <= {
						chn1_mat[chn0_rmat_row*4+3][chn0_rmat_col*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn0_rmat_row*4+2][chn0_rmat_col*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn0_rmat_row*4+1][chn0_rmat_col*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn0_rmat_row*4+0][chn0_rmat_col*4*DATA_WIDTH +:4*DATA_WIDTH]
					};
				end
				else if(chn0_wr_en&~chn0_full&chn0_rmat_bit_map_lock[0])begin
					chn0_rmat_lock <= {chn0_rmat_lock[DATA_WIDTH-1:0],chn0_rmat_lock[16*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			WAIT_S_DLY:begin
				if(chn0_wr_en&~chn0_full&chn0_rmat_bit_map_lock[0])begin
					chn0_rmat_lock <= {chn0_rmat_lock[DATA_WIDTH-1:0],chn0_rmat_lock[16*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
		endcase
	end

	always@(posedge clk)begin
		case(chn0_state_c)
			CAL_QK:begin
				if(wq_cs&wq_ren)begin
					chn0_rmat_bit_map_lock <= wq_bit_map;
				end
				else if(chn0_wr_en&~chn0_full)begin
					chn0_rmat_bit_map_lock <= {chn0_rmat_bit_map_lock[0],chn0_rmat_bit_map_lock[15:1]};
				end
			end
			WAIT_QK_DLY,WAIT_S_DLY:begin
				if(chn0_wr_en&~chn0_full)begin
					chn0_rmat_bit_map_lock <= {chn0_rmat_bit_map_lock[0],chn0_rmat_bit_map_lock[15:1]};
				end
			end
			CAL_S:begin
				if(chn0_rmat_cs&chn0_rmat_ren)begin
					chn0_rmat_bit_map_lock <= 16'hffff;
				end
				else if(chn0_wr_en&~chn0_full)begin
					chn0_rmat_bit_map_lock <= {chn0_rmat_bit_map_lock[0],chn0_rmat_bit_map_lock[15:1]};
				end
			end
		endcase
	end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            chn0_col_end_lock <= 1'b0;
            chn0_row_end_lock <= 1'b0;
            chn0_frm_end_lock <= 1'b0;
        end else if(chn0_cal_cnt == 4'd0) begin
            if(chn0_lmat_cs&chn0_lmat_ren) begin
                chn0_col_end_lock <= chn0_col_end;
                chn0_row_end_lock <= chn0_row_end;
                chn0_frm_end_lock <= chn0_frm_end;
            end
        end else if(chn0_cal_cnt == 4'd15) begin
            if(chn0_lmat_cs&chn0_lmat_ren) begin
                chn0_col_end_lock <= chn0_col_end;
                chn0_row_end_lock <= chn0_row_end;
                chn0_frm_end_lock <= chn0_frm_end;
            end else if(chn0_wr_en&~chn0_full) begin
                chn0_col_end_lock <= 1'b0;
                chn0_row_end_lock <= 1'b0;
                chn0_frm_end_lock <= 1'b0;
            end
        end
    end
	
	always@(posedge clk) begin
		case(chn1_state_c)
			CAL_QK,CAL_V:begin
				if(x_cs&x_ren)begin
					chn1_lmat_lock <= x;
				end else if(chn1_wr_en&~chn1_full)begin
					chn1_lmat_lock <= {chn1_lmat_lock[DATA_WIDTH-1:0],chn1_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			CAL_S:begin
				if(chn1_wr_en&~chn1_full)begin
					chn1_lmat_lock <= {chn1_lmat_lock[DATA_WIDTH-1:0],chn1_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			ATTENTION:begin
				if(chn1_lmat_cs&chn1_lmat_ren)begin
					chn1_lmat_lock <= chn0_mat[chn1_lmat_row][chn1_lmat_col*DATA_NUM*DATA_WIDTH+:DATA_NUM*DATA_WIDTH];
				end else if(chn1_wr_en&~chn1_full)begin
					chn1_lmat_lock <= {chn1_lmat_lock[DATA_WIDTH-1:0],chn1_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			WAIT_ATTENTION_DLY:begin
				if(chn1_wr_en&~chn1_full)begin
					chn1_lmat_lock <= {chn1_lmat_lock[DATA_WIDTH-1:0],chn1_lmat_lock[DATA_NUM*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
		endcase
	end

	always@(posedge clk)begin
		case(chn1_state_c)
			CAL_QK:begin
				if(wk_cs&wk_ren)begin
					chn1_rmat_lock <= {{8*DATA_WIDTH{1'b0}},wk};
				end else if(chn1_wr_en&~chn1_full&chn1_rmat_bit_map_lock[0])begin
					chn1_rmat_lock <= {{8*DATA_WIDTH{1'b0}},chn1_rmat_lock[DATA_WIDTH-1:0],chn1_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
			CAL_S,WAIT_AV_DONE:begin
				if(chn1_wr_en&~chn1_full&chn1_rmat_bit_map_lock[0])begin
					chn1_rmat_lock <= {{8*DATA_WIDTH{1'b0}},chn1_rmat_lock[DATA_WIDTH-1:0],chn1_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
            CAL_V:begin
                if(wv_cs&wv_ren)begin
					chn1_rmat_lock <= {{8*DATA_WIDTH{1'b0}},wv};
				end else if(chn1_wr_en&~chn1_full&chn1_rmat_bit_map_lock[0])begin
					chn1_rmat_lock <= {{8*DATA_WIDTH{1'b0}},chn1_rmat_lock[DATA_WIDTH-1:0],chn1_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
				end
            end
            ATTENTION:begin
                if(chn1_lmat_cs&chn1_lmat_ren)begin
					chn1_rmat_lock <= {
						chn1_mat[chn1_rmat_col*4+3][chn1_rmat_row*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn1_rmat_col*4+2][chn1_rmat_row*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn1_rmat_col*4+1][chn1_rmat_row*4*DATA_WIDTH +:4*DATA_WIDTH],
						chn1_mat[chn1_rmat_col*4+0][chn1_rmat_row*4*DATA_WIDTH +:4*DATA_WIDTH]
					};
				end else if(chn1_wr_en&~chn1_full&chn1_rmat_bit_map_lock[0])begin
					chn1_rmat_lock <= {chn1_rmat_lock[DATA_WIDTH-1:0],chn1_rmat_lock[16*DATA_WIDTH-1:DATA_WIDTH]};
				end
            end
			WAIT_ATTENTION_DLY:begin
				if(chn1_wr_en&~chn1_full&chn1_rmat_bit_map_lock[0])begin
					chn1_rmat_lock <= {chn1_rmat_lock[DATA_WIDTH-1:0],chn1_rmat_lock[16*DATA_WIDTH-1:DATA_WIDTH]};
				end
			end
		endcase
	end
    
	always@(posedge clk)begin
		case(chn1_state_c)
			CAL_QK:begin
				if(wk_cs&wk_ren)begin
					chn1_rmat_bit_map_lock <= wk_bit_map;
				end else if(chn1_wr_en&~chn1_full)begin
					chn1_rmat_bit_map_lock <= {chn1_rmat_bit_map_lock[0],chn1_rmat_bit_map_lock[15:1]};
				end
			end
			CAL_S,WAIT_AV_DONE,WAIT_ATTENTION_DLY:begin
				if(chn1_wr_en&~chn1_full)begin
					chn1_rmat_bit_map_lock <= {chn1_rmat_bit_map_lock[0],chn1_rmat_bit_map_lock[15:1]};
				end
			end
            CAL_V:begin
                if(wv_cs&wv_ren)begin
					chn1_rmat_bit_map_lock <= wv_bit_map;
				end else if(chn1_wr_en&~chn1_full)begin
					chn1_rmat_bit_map_lock <= {chn1_rmat_bit_map_lock[0],chn1_rmat_bit_map_lock[15:1]};
				end
            end
            ATTENTION:begin
				if(chn1_rmat_cs&chn1_rmat_ren)begin
					chn1_rmat_bit_map_lock <= 16'hffff;
				end else if(chn1_wr_en&~chn1_full)begin
					chn1_rmat_bit_map_lock <= {chn1_rmat_bit_map_lock[0],chn1_rmat_bit_map_lock[15:1]};
				end
            end
		endcase
	end

    always @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_col_end_lock <= 1'b0;
            chn1_row_end_lock <= 1'b0;
            chn1_frm_end_lock <= 1'b0;
        end else if(chn1_cal_cnt == 4'd0)begin
            if(chn1_lmat_cs&chn1_lmat_ren)begin
                chn1_col_end_lock <= chn1_col_end;
                chn1_row_end_lock <= chn1_row_end;
                chn1_frm_end_lock <= chn1_frm_end;
            end
        end else if(chn1_cal_cnt == 4'd15)begin
            if(chn1_lmat_cs&chn1_lmat_ren)begin
                chn1_col_end_lock <= chn1_col_end;
                chn1_row_end_lock <= chn1_row_end;
                chn1_frm_end_lock <= chn1_frm_end;
            end else if(chn1_wr_en&~chn1_full)begin
                chn1_col_end_lock <= 1'b0;
                chn1_row_end_lock <= 1'b0;
                chn1_frm_end_lock <= 1'b0;
            end
        end
    end

	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			wv_ok_lock <= 1'b0;
		end else if(wv_ok&~wv_ok_lock)begin
			wv_ok_lock <= 1'b1;
		end else if(chn1_state_c==CAL_S && chn1_rmat_ok)begin
			wv_ok_lock <= 1'b0;
		end
	end
	
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			a_ok_lock <= 1'b0;
		end else if(chn0_state_c == WAIT_AV_DONE && a_ok_lock == 1'b0 && chn0_mat_real_ok)begin//????
			a_ok_lock <= 1'b1;
		end else if(chn1_state_c == WAIT_AV_DONE && chn1_rmat_ok)begin
			a_ok_lock <= 1'b0;
		end
	end

	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn0_wr_en <= 1'b0;
		end else begin
			case(chn0_state_c)
				CAL_QK:begin
					if(x_cs&x_ren&wq_cs&wq_ren&~chn0_wr_en)begin
						chn0_wr_en<= 1'b1;
					end else if(chn0_cal_cnt==4'd15&chn0_wr_en&~chn0_full)begin
						chn0_wr_en<= 1'b0;
					end
				end
				WAIT_QK_DLY,WAIT_S_DLY:begin
					if(chn0_cal_cnt==4'd15&chn0_wr_en&~chn0_full)begin
						chn0_wr_en<= 1'b0;
					end
				end
                CAL_S:begin
                    if(chn0_lmat_cs&chn0_lmat_ren&chn0_rmat_cs&chn0_rmat_ren&~chn0_wr_en)begin
						chn0_wr_en<= 1'b1;
					end else if(chn0_cal_cnt==4'd15&chn0_wr_en&~chn0_full)begin
						chn0_wr_en<= 1'b0;
					end
                end
			endcase
		end
	end
		
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn0_cal_cnt <= 4'd0;
		end else if(chn0_wr_en&~chn0_full)begin
			if(chn0_cal_cnt==4'd15)begin
				chn0_cal_cnt <= 4'd0;
			end else begin
				chn0_cal_cnt <= chn0_cal_cnt+4'd1;
			end
		end
	end
	
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn1_wr_en <= 1'b0;
		end else begin
			case(chn1_state_c)
                CAL_QK:begin
					if(x_cs&x_ren&wk_cs&wk_ren&~chn1_wr_en)begin
						chn1_wr_en<= 1'b1;
					end else if(chn1_cal_cnt==4'd15&chn1_wr_en&~chn1_full)begin
						chn1_wr_en<= 1'b0;
					end
				end
				CAL_S,WAIT_AV_DONE,WAIT_ATTENTION_DLY:begin
					if(chn1_cal_cnt==4'd15&chn1_wr_en&~chn1_full)begin
						chn1_wr_en<= 1'b0;
					end
				end
                CAL_V:begin
                	if(x_cs&x_ren&wv_cs&wv_ren&~chn1_wr_en)begin
						chn1_wr_en<= 1'b1;
					end else if(chn1_cal_cnt==4'd15&chn1_wr_en&~chn1_full)begin
						chn1_wr_en<= 1'b0;
					end
                end
                ATTENTION:begin
                	if(chn1_lmat_cs&chn1_lmat_ren&chn1_rmat_cs&chn1_rmat_ren&~chn1_wr_en)begin
						chn1_wr_en<= 1'b1;
					end else if(chn1_cal_cnt==4'd15&chn1_wr_en&~chn1_full)begin
						chn1_wr_en<= 1'b0;
					end
                end
			endcase
		end
	end
		
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn1_cal_cnt <= 4'd0;
		end else if(chn1_wr_en&~chn1_full)begin
			if(chn1_cal_cnt==4'd15)begin
				chn1_cal_cnt <= 4'd0;
			end else begin
				chn1_cal_cnt <= chn1_cal_cnt+4'd1;
			end
		end
	end

	assign chn0_din[54:39] = chn0_rmat_lock[DATA_WIDTH-1:0];
	assign chn0_din[38:23] = chn0_rmat_bit_map_lock[0] ? chn0_lmat_lock[DATA_WIDTH-1:0] : 'd0;
	assign chn0_din[22:19] = chn0_state_c;
	assign chn0_din[18   ] = chn0_cal_cnt == 4'd15 ? 1'b1 : 1'b0;
	assign chn0_din[17   ] = chn0_din[18]&chn0_row_end_lock;
	assign chn0_din[16   ] = chn0_din[18]&chn0_frm_end_lock;
	assign chn0_din[15:9 ] = chn0_rmat_col;
	assign chn0_din[8:7  ] = chn0_cal_cnt[3:2];
	assign chn0_din[6:0  ] = chn0_lmat_row;
    
    assign chn1_din[54:39] = chn1_rmat_lock[DATA_WIDTH-1:0];
	assign chn1_din[38:23] = chn1_rmat_bit_map_lock[0] ? chn1_lmat_lock[DATA_WIDTH-1:0] : 'd0;
	assign chn1_din[22:19] = chn1_state_c;
	assign chn1_din[18   ] = chn1_cal_cnt == 4'd15 ? 1'b1 : 1'b0;
	assign chn1_din[17   ] = chn1_din[18]&chn1_row_end_lock;
	assign chn1_din[16   ] = chn1_din[18]&chn1_frm_end_lock;
	assign chn1_din[15:9 ] = chn1_rmat_col;
	assign chn1_din[8:7  ] = chn1_cal_cnt[3:2];
	assign chn1_din[6:0  ] = chn1_lmat_row;

	assign chn0_rd_en = ~chn0_empty;
	assign chn1_rd_en = ~chn1_empty;

	SYNC_FIFO #(.DATA_WIDTH(55)) U0_SYNC_FIFO(
		.clk  (clk  ),
		.rst_n(rst_n),
		.wr_en(chn0_wr_en),
		.din  (chn0_din  ),
		.full (chn0_full ),
		.rd_en(chn0_rd_en),
		.dout (chn0_dout ),
		.empty(chn0_empty)
    );
	
	SYNC_FIFO #(.DATA_WIDTH(55)) U1_SYNC_FIFO(
		.clk  (clk  ),
		.rst_n(rst_n),
		.wr_en(chn1_wr_en),
		.din  (chn1_din  ),
		.full (chn1_full ),
		.rd_en(chn1_rd_en),
		.dout (chn1_dout ),
		.empty(chn1_empty)
    );
	
	
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn0_mul_vld_in <= 1'b0;
		end else if(~chn0_empty&chn0_rd_en)begin
			chn0_mul_vld_in <= 1'b1;
		end else begin
			chn0_mul_vld_in <= 1'b0;
		end
	end

	MUL U0_MUL(
        .clk                    (clk                            ),
        .rst_n                  (rst_n                          ),
        .vld_in                 (chn0_mul_vld_in                ),
        .info_in                (chn0_dout[22:0]                ),
        .data0                  (chn0_dout[38:23]               ),
        .data1                  (chn0_dout[54:39]               ),
        .vld_out                (chn0_mul_vld                   ),
        .info_out               (chn0_mul_info_out              ),
        .mul                    (chn0_mul                       )
    );
	
	assign chn0_add_data1 = chn0_mat_oneline_tmp[(4*chn0_mul_info_out[15:9]+
	chn0_mul_info_out[8:7])*DATA_WIDTH+:DATA_WIDTH];

	ADD U0_ADD(
        .info_in                (chn0_mul_info_out              ),
        .data0                  (chn0_mul                       ),
        .data1                  (chn0_add_data1                 ),
        .in_vld                 (chn0_mul_vld                   ),
        .out_vld                (chn0_sum_vld                   ),
        .info_out               (chn0_sum_info_out              ),
        .sum                    (chn0_sum                       )
    );
	
    assign chn0_up_en = chn0_state_c == DENOMINTOR_SUM || chn0_state_c == SOFT_MAX ? chn0_lmat_cs:
						chn0_cal_cnt == 4'd15 && chn0_wr_en && ~chn0_full ? 1'b1 : 1'b0;
	assign chn0_mat_real_ok = chn0_state_c == WAIT_SOFT_MAX_DLY ? soft_max_vld&
	soft_max_info_out[14]:chn0_sum_info_out[16];

    assign soft_max_info_in  = {chn0_state_c,chn0_row_end,chn0_frm_end,chn0_lmat_col,chn0_lmat_row};
    assign sum_clear         = chn0_state_c == WAIT_SOFT_MAX_DLY ? chn0_lmat_cs&
	chn0_row_end : 1'b0;
    assign denomintor_in_vld = chn0_state_c == DENOMINTOR_SUM ? chn0_lmat_cs : 1'b0; 
    assign numerator_in_vld  = chn0_state_c == SOFT_MAX ? chn0_lmat_cs : 1'b0; 
    assign denomintor_in     = chn0_state_c == DENOMINTOR_SUM ? chn0_mat[chn0_lmat_row][chn0_lmat_col*4*DATA_WIDTH+:4*DATA_WIDTH] : 'd0;
    assign numerator_in      = chn0_state_c == SOFT_MAX ? chn0_mat[chn0_lmat_row][chn0_lmat_col*4*DATA_WIDTH+:4*DATA_WIDTH] : 'd0;

	SOFT_MAX #(
        .DATA_WIDTH             (DATA_WIDTH                     ),
        .DATA_NUM               (DATA_NUM                       ),
        .INFO_WIDTH             (SOFT_MAX_INFO_WIDTH            ) 
    )
    U_SOFT_MAX(
        .clk                    (clk                                           ),
        .rst_n                  (rst_n                                         ),
        .sum_clear              (sum_clear                                     ),
        .soft_max_info_in       (soft_max_info_in[SOFT_MAX_INFO_WIDTH-1:0]     ),
        .denomintor_in_vld      (denomintor_in_vld                             ),
        .numerator_in_vld       (numerator_in_vld                              ),
        .denomintor_in          (denomintor_in[DATA_NUM*DATA_WIDTH-1:0]        ),
        .numerator_in           (numerator_in[DATA_NUM*DATA_WIDTH-1:0]         ),
        .denomintor_sum_ok      (denomintor_sum_ok                             ),
        .out_vld                (soft_max_vld                                  ),
        .data_out               (soft_max_data_out[DATA_NUM*DATA_WIDTH-1:0]    ),
        .soft_max_info_out      (soft_max_info_out[SOFT_MAX_INFO_WIDTH-1:0]    )
    );

	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn0_mat_oneline_tmp <= {(DATA_WIDTH*W_MAT_W){1'b0}};
		end else if(chn0_sum_vld)begin
			if(chn0_sum_info_out[17])begin
				chn0_mat_oneline_tmp <= {(DATA_WIDTH*W_MAT_W){1'b0}};
			end else begin
				chn0_mat_oneline_tmp[(4*chn0_sum_info_out[15:9]+chn0_sum_info_out[8:7])*
				DATA_WIDTH+:DATA_WIDTH] <= chn0_sum;
			end
		end else if(soft_max_vld)begin
			chn0_mat_oneline_tmp[4*soft_max_info_out[13:7]*DATA_WIDTH+:DATA_NUM*DATA_WIDTH] <= 
			soft_max_data_out;
		end
	end
	
	always@(posedge clk)begin
		if(chn0_sum_vld&chn0_sum_info_out[17])begin
			case(chn0_sum_info_out[22:19])
				CAL_QK,WAIT_QK_DLY:begin
					chn0_mat[chn0_sum_info_out[6:0]] <= {chn0_sum,
					chn0_mat_oneline_tmp[DATA_WIDTH*(W_MAT_W-1)-1:0]};
				end
				CAL_S,WAIT_S_DLY:begin
					chn0_mat[chn0_sum_info_out[6:0]][W_MAT_W*DATA_WIDTH-1-:DATA_WIDTH] <= 
					{chn0_sum[15],2'd0,chn0_sum[14:12],chn0_sum[9:0]};//SCALE / 8
					for(k = 0;k<W_MAT_W-1;k = k+1)begin
						chn0_mat[chn0_sum_info_out[6:0]][k*DATA_WIDTH+:DATA_WIDTH] <= 
						{chn0_mat_oneline_tmp[k*DATA_WIDTH+15],2'd0,
						chn0_mat_oneline_tmp[k*DATA_WIDTH+12+:3],
						chn0_mat_oneline_tmp[k*DATA_WIDTH+:9]};// SCALE /8
                    end
				end
			endcase
		end else if(soft_max_vld&soft_max_info_out[15])begin
			chn0_mat[soft_max_info_out[6:0]] <= {soft_max_info_out,
			chn0_mat_oneline_tmp[(W_MAT_W-4)*DATA_WIDTH-1:0]};
        end
    end

	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn1_mul_vld_in <= 1'b0;
		end else if(~chn1_empty&chn1_rd_en)begin
			chn1_mul_vld_in <= 1'b1;
		end else begin
			chn1_mul_vld_in <= 1'b0;
		end
	end
    
	MUL U1_MUL(
        .clk                    (clk                            ),
        .rst_n                  (rst_n                          ),
        .vld_in                 (chn1_mul_vld_in                ),
        .info_in                (chn1_dout[22:0]                ),
        .data0                  (chn1_dout[38:23]               ),
        .data1                  (chn1_dout[54:39]               ),
        .vld_out                (chn1_mul_vld                   ),
        .info_out               (chn1_mul_info_out              ),
        .mul                    (chn1_mul                       )
    );
	
	assign chn1_add_data1 = chn1_mat_oneline_tmp[(4*chn1_mul_info_out[15:9]+
	chn1_mul_info_out[8:7])*DATA_WIDTH+:DATA_WIDTH];
	ADD U1_ADD(
        .info_in                (chn1_mul_info_out              ),
        .data0                  (chn1_mul                       ),
        .data1                  (chn1_add_data1                 ),
        .in_vld                 (chn1_mul_vld                   ),
        .out_vld                (chn1_sum_vld                   ),
        .info_out               (chn1_sum_info_out              ),
        .sum                    (chn1_sum                       )
    );
    
    assign chn1_up_en = chn1_cal_cnt == 4'd15 && chn1_wr_en && ~chn1_full ? 1'b1 : 1'b0;
	assign chn1_mat_real_ok = chn1_sum_info_out[16];
	
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			chn1_mat_oneline_tmp <= {(DATA_WIDTH*W_MAT_W){1'b0}};
		end else if(chn1_sum_vld)begin
			if(chn1_sum_info_out[17])begin
				chn1_mat_oneline_tmp <= {(DATA_WIDTH*W_MAT_W){1'b0}};
			end else begin
				chn1_mat_oneline_tmp[(4*chn1_sum_info_out[15:9]+chn1_sum_info_out[8:7])*
				DATA_WIDTH+:DATA_WIDTH] <= chn1_sum;
			end
		end
	end
	
	always@(posedge clk)begin
		if(chn1_sum_vld&chn1_sum_info_out[17])begin
			chn1_mat[chn1_sum_info_out[6:0]] <= {chn1_sum,chn1_mat_oneline_tmp[DATA_WIDTH*
			(W_MAT_W-1)-1:0]};
		end
    end

	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			attention_vld <= 1'b0;
		end else if(chn1_state_c == WAIT_ATTENTION_DLY && chn1_mat_real_ok)begin
			attention_vld <= 1'b1;
		end else begin
			attention_vld <= 1'b0;
		end
	end

	generate
		genvar I;
		for(I =0; I < X_MAT_H;I = I+1)begin:ATTENTION_JOIN
			assign attention[I*(W_MAT_W*DATA_WIDTH)+:W_MAT_W*DATA_WIDTH] = chn1_mat[I];
		end
	endgenerate
endmodule