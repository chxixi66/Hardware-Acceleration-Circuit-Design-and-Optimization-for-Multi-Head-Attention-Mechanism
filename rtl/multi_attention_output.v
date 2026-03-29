// 多头注意力输出处理模块
// 功能：将8个注意力头的输出通过W^O投影，生成与输入X维度相同的输出Z
// 注意：W^O权重矩阵加载逻辑与项目中Q、K、V权重矩阵保持一致
module multi_head_output#(
    parameter DATA_WIDTH     = 16,      // 数据位宽
    parameter HEAD_NUM       = 8,       // 注意力头数量
    parameter HEAD_DIM       = 64,      // 每个注意力头的维度
    parameter MODEL_DIM      = 512      // 模型总维度（与X_MAT_W保持一致）
)(
    input                            clk                     ,
    input                            rst_n                   ,
    
    // 8个注意力头的输入
    input                            attention_vld           ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention0      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention1      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention2      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention3      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention4      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention5      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention6      ,
    input  [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention7      ,
    
    // W^O权重矩阵接口 - 与Q、K、V接口保持一致
    input                            wo_ok                   ,
    output                           wo_ren                  ,
    output                           wo_cs                   ,
    output [12:0]                    wo_rd_addr              ,
    input  [8*DATA_WIDTH-1:0]        wo                      ,
    input  [16-1:0]                  wo_bit_map              ,
    
    // 输出接口 - 与输入X维度相同（512×64）
    output                           z_vld                   ,
    output [MODEL_DIM*HEAD_DIM*DATA_WIDTH-1:0]z_data          
);
    
    // 状态定义 - 与项目中状态机定义风格保持一致
    localparam IDEL            = 4'd0  ,
               CONCAT_HEADS    = 4'd1  ,
               LOAD_WO         = 4'd2  ,
               MATRIX_PROJECT  = 4'd3  ,
               OUTPUT_Z        = 4'd4  ;
    
    // 内部信号
    reg [3:0]    state_c              ; // 当前状态
    reg [3:0]    state_n              ; // 下一状态
    
    // 矩阵存储
    reg [DATA_WIDTH-1:0] concatenated_mat[HEAD_DIM-1:0][MODEL_DIM-1:0]; // 拼接后的矩阵 (64×512)
    reg [DATA_WIDTH-1:0] wo_mat[MODEL_DIM-1:0][MODEL_DIM-1:0];          // W^O权重矩阵 (512×512)
    reg [DATA_WIDTH-1:0] z_mat[HEAD_DIM-1:0][MODEL_DIM-1:0];            // 输出矩阵Z (64×512)
    
    // 地址计数器
    reg [6:0]    row_cnt              ; // 行计数器 (0-63)
    reg [6:0]    col_cnt              ; // 列计数器 (0-511)
    reg [6:0]    k_cnt                ; // K维度计数器 (0-511)
    reg [2:0]    head_cnt             ; // 头计数器 (0-7)
    
    // 控制信号
    reg          concat_en            ;
    reg          load_wo_en           ;
    reg          project_en           ;
    reg          output_en            ;
    
    // 锁存器 - 与项目中权重锁存器风格保持一致
    reg [HEAD_DIM*HEAD_DIM*DATA_WIDTH-1:0]attention_lock[HEAD_NUM-1:0];
    reg [16*DATA_WIDTH-1:0]               wo_rmat_lock            ; // W^O权重锁存器
    reg [15:0]                            wo_rmat_bit_map_lock    ; // W^O位图锁存器
    reg [3:0]                             wo_cal_cnt              ; // W^O计算计数器
    
    // FIFO控制信号
    reg                                   wo_wr_en                ;
    wire                                  wo_full                 ;
    wire [54:0]                           wo_din                  ;
    wire [54:0]                           wo_dout                 ;
    wire                                  wo_empty                ;
    wire                                  wo_rd_en_int            ;
    
    // 乘法器和加法器接口信号
    reg                                   mul_vld_in              ;
    wire                                  mul_vld                 ;
    wire [22:0]                           mul_info_out            ;
    wire [DATA_WIDTH-1:0]                 mul_out                 ;
    
    wire [DATA_WIDTH-1:0]                 add_data1               ;
    reg                                   add_vld_in              ;
    wire                                  add_vld                 ;
    wire [22:0]                           add_info_out            ;
    wire [DATA_WIDTH-1:0]                 add_out                 ;
    
    // ------------------------------- 状态机实现 -------------------------------
    // 状态寄存器更新
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            state_c <= IDEL;
        end
        else begin
            state_c <= state_n;
        end
    end
    
    // 状态组合逻辑
    always @(*)begin
        case(state_c)
            IDEL:begin
                if(attention_vld)begin
                    state_n = CONCAT_HEADS;
                end
                else begin
                    state_n = IDEL;
                end
            end
            CONCAT_HEADS:begin
                if(row_cnt == HEAD_DIM-1 && col_cnt == MODEL_DIM-1)begin
                    state_n = LOAD_WO;
                end
                else begin
                    state_n = CONCAT_HEADS;
                end
            end
            LOAD_WO:begin
                if(row_cnt == MODEL_DIM-1 && col_cnt == MODEL_DIM-1)begin
                    state_n = MATRIX_PROJECT;
                end
                else begin
                    state_n = LOAD_WO;
                end
            end
            MATRIX_PROJECT:begin
                if(row_cnt == HEAD_DIM-1 && col_cnt == MODEL_DIM-1 && k_cnt == MODEL_DIM-1)begin
                    state_n = OUTPUT_Z;
                end
                else begin
                    state_n = MATRIX_PROJECT;
                end
            end
            OUTPUT_Z:begin
                state_n = IDEL;
            end
            default:begin
                state_n = IDEL;
            end
        endcase
    end
    
    // 输出控制信号
    always @(*)begin
        concat_en   = 1'b0;
        load_wo_en  = 1'b0;
        project_en  = 1'b0;
        output_en   = 1'b0;
        
        case(state_c)
            CONCAT_HEADS:begin
                concat_en = 1'b1;
            end
            LOAD_WO:begin
                load_wo_en = 1'b1;
            end
            MATRIX_PROJECT:begin
                project_en = 1'b1;
            end
            OUTPUT_Z:begin
                output_en = 1'b1;
            end
        endcase
    end
    
    // ------------------------------- 计数器控制 -------------------------------
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            row_cnt <= 7'd0;
            col_cnt <= 7'd0;
            k_cnt <= 7'd0;
            head_cnt <= 3'd0;
        end
        else begin
            case(state_c)
                CONCAT_HEADS:begin
                    head_cnt <= col_cnt / HEAD_DIM; // 计算当前处理的注意力头
                    
                    if(col_cnt == MODEL_DIM-1)begin
                        col_cnt <= 7'd0;
                        if(row_cnt == HEAD_DIM-1)begin
                            row_cnt <= 7'd0;
                        end
                        else begin
                            row_cnt <= row_cnt + 1'b1;
                        end
                    end
                    else begin
                        col_cnt <= col_cnt + 1'b1;
                    end
                end
                LOAD_WO:begin
                    if(col_cnt == MODEL_DIM-1)begin
                        col_cnt <= 7'd0;
                        if(row_cnt == MODEL_DIM-1)begin
                            row_cnt <= 7'd0;
                        end
                        else begin
                            row_cnt <= row_cnt + 1'b1;
                        end
                    end
                    else begin
                        col_cnt <= col_cnt + 1'b1;
                    end
                end
                MATRIX_PROJECT:begin
                    if(k_cnt == MODEL_DIM-1)begin
                        k_cnt <= 7'd0;
                        if(col_cnt == MODEL_DIM-1)begin
                            col_cnt <= 7'd0;
                            if(row_cnt == HEAD_DIM-1)begin
                                row_cnt <= 7'd0;
                            end
                            else begin
                                row_cnt <= row_cnt + 1'b1;
                            end
                        end
                        else begin
                            col_cnt <= col_cnt + 1'b1;
                        end
                    end
                    else begin
                        k_cnt <= k_cnt + 1'b1;
                    end
                end
                default:begin
                    row_cnt <= 7'd0;
                    col_cnt <= 7'd0;
                    k_cnt <= 7'd0;
                    head_cnt <= 3'd0;
                end
            endcase
        end
    end
    
    // ------------------------------- 数据锁存 -------------------------------
    always@(posedge clk)begin
        if(attention_vld)begin
            attention_lock[0] <= attention0;
            attention_lock[1] <= attention1;
            attention_lock[2] <= attention2;
            attention_lock[3] <= attention3;
            attention_lock[4] <= attention4;
            attention_lock[5] <= attention5;
            attention_lock[6] <= attention6;
            attention_lock[7] <= attention7;
        end
    end
    
    // ------------------------------- W^O权重矩阵加载逻辑 - 与Q、K、V保持一致 -------------------------------
    // W^O权重锁存器 - 仿照项目中Q、K、V权重加载逻辑
    always@(posedge clk)begin
        case(state_c)
            LOAD_WO:begin
                if(wo_cs&wo_ren)begin
                    // 仿照项目中权重加载方式，高8个数据位补0
                    wo_rmat_lock <= {{8*DATA_WIDTH{1'b0}}, wo};
                end
                else if(wo_wr_en&~wo_full&wo_rmat_bit_map_lock[0])begin
                    // 数据移位逻辑 - 与项目中移位方式一致
                    wo_rmat_lock <= {{8*DATA_WIDTH{1'b0}}, wo_rmat_lock[DATA_WIDTH-1:0], wo_rmat_lock[8*DATA_WIDTH-1:DATA_WIDTH]};
                end
            end
        endcase
    end
    
    // W^O位图锁存器 - 仿照项目中位图处理逻辑
    always@(posedge clk)begin
        case(state_c)
            LOAD_WO:begin
                if(wo_cs&wo_ren)begin
                    wo_rmat_bit_map_lock <= wo_bit_map;
                end
                else if(wo_wr_en&~wo_full)begin
                    // 位图移位逻辑 - 与项目中位图移位方式一致
                    wo_rmat_bit_map_lock <= {wo_rmat_bit_map_lock[0], wo_rmat_bit_map_lock[15:1]};
                end
            end
        endcase
    end
    
    // W^O计算计数器 - 仿照项目中计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            wo_cal_cnt <= 4'd0;
        end else if(state_c == LOAD_WO) begin
            if(wo_cal_cnt == 4'd15) begin
                wo_cal_cnt <= 4'd0;
            end else begin
                wo_cal_cnt <= wo_cal_cnt + 1'b1;
            end
        end else begin
            wo_cal_cnt <= 4'd0;
        end
    end
    
    // W^O矩阵构建 - 使用移位后的数据
    always@(posedge clk)begin
        if(state_c == LOAD_WO && wo_rmat_bit_map_lock[0])begin
            // 使用移位后的数据填充权重矩阵
            wo_mat[row_cnt][col_cnt] <= wo_rmat_lock[DATA_WIDTH-1:0];
        end
    end
    
    // ------------------------------- 多头拼接 -------------------------------
    // 拼接注意力头输出
    always@(posedge clk)begin
        if(concat_en && head_cnt < HEAD_NUM)begin
            concatenated_mat[row_cnt][col_cnt] <= attention_lock[head_cnt][(row_cnt*HEAD_DIM + (col_cnt % HEAD_DIM))*DATA_WIDTH +: DATA_WIDTH];
        end
    end
    
    // ------------------------------- 矩阵乘法实现 -------------------------------
    // 乘法器控制
    always@(posedge clk)begin
        if(project_en)begin
            mul_vld_in <= 1'b1;
        end
        else begin
            mul_vld_in <= 1'b0;
        end
    end
    
    // 乘法器实例化
    MUL U_MUL(
        .clk            (clk           ),
        .rst_n          (rst_n         ),
        .mul_vld_in     (mul_vld_in    ),
        .mul_info_in    ({16'd0, row_cnt, col_cnt, k_cnt}),
        .mul_a          (concatenated_mat[row_cnt][k_cnt]),
        .mul_b          (wo_mat[k_cnt][col_cnt]),
        .mul_vld        (mul_vld       ),
        .mul_info_out   (mul_info_out  ),
        .mul            (mul_out       )
    );
    
    // 加法器控制
    always@(posedge clk)begin
        add_vld_in <= mul_vld;
    end
    
    // 加法器输入数据1 - 累加前的值
    assign add_data1 = (k_cnt == 0) ? {DATA_WIDTH{1'b0}} : z_mat[row_cnt][col_cnt];
    
    // 加法器实例化
    ADD U_ADD(
        .clk            (clk           ),
        .rst_n          (rst_n         ),
        .add_vld_in     (add_vld_in    ),
        .add_info_in    (mul_info_out  ),
        .add_a          (add_data1     ),
        .add_b          (mul_out       ),
        .add_vld        (add_vld       ),
        .add_info_out   (add_info_out  ),
        .add            (add_out       )
    );
    
    // 结果累加 - 更新输出矩阵Z
    always@(posedge clk)begin
        if(add_vld)begin
            z_mat[add_info_out[13:7]][add_info_out[6:0]] <= add_out;
        end
    end
    
    // ------------------------------- 输出接口 -------------------------------
    // 输出有效信号
    assign z_vld = output_en;
    
    // 输出数据拼接 - 确保维度为512×64，与输入X相同
    genvar i, j;
    generate
        for(i = 0; i < HEAD_DIM; i = i + 1)begin:OUT_ROW
            for(j = 0; j < MODEL_DIM; j = j + 1)begin:OUT_COL
                assign z_data[(i*MODEL_DIM + j)*DATA_WIDTH +: DATA_WIDTH] = z_mat[i][j];
            end
        end
    endgenerate
    
    // ------------------------------- W^O权重接口控制 - 与项目中接口控制保持一致 -------------------------------
    assign wo_cs = load_wo_en;
    assign wo_ren = load_wo_en;
    assign wo_rd_addr = row_cnt * MODEL_DIM + col_cnt;
    
    // W^O FIFO相关信号（根据需要可实例化FIFO）
    assign wo_wr_en = load_wo_en; // 简化实现，实际应根据状态和计数器控制
    assign wo_din = 0; // 简化实现
    assign wo_rd_en_int = 0; // 简化实现
    
endmodule