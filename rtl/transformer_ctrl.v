module TRANSFORMER_CTRL#(
    parameter X_MAT_W             = 512   , 
    parameter X_MAT_H             = 64    , 
    parameter W_MAT_W             = 64    , 
    parameter W_MAT_H             = 512   , 
    parameter IDEL                = 4'd0  , 
    parameter CAL_QK              = 4'd1  , 
    parameter WAIT_QK_DLY         = 4'd2  , 
    parameter CAL_S               = 4'd3  , 
    parameter CAL_V               = 4'd4  , 
    parameter WAIT_S_DLY          = 4'd5  , 
    parameter DENOMINTOR_SUM      = 4'd6  , 
    parameter WAIT_DENOMINTOR_DLY = 4'd7  , 
    parameter SOFT_MAX            = 4'd8  , 
    parameter WAIT_SOFT_MAX_DLY   = 4'd9  , 
    parameter WAIT_AV_DONE        = 4'ha  , 
    parameter ATTENTION           = 4'hb  , 
    parameter WAIT_ATTENTION_DLY  = 4'hc
)(
    input               clk          , 
    input               rst_n        , 
    
    //Channel0
    input               chn0_lmat_ok ,//left side matrix of channel 0 is ready;
    output reg          chn0_lmat_cs ,//sram of saving left-side matrix is selected;
    output              chn0_lmat_ren,//read enable,0: read disble 1:read enable
    input               chn0_rmat_ok , //right side matrix of channel 0 is ready;
    output reg          chn0_rmat_cs , //sram of saving right-side matrix is selected;
    output              chn0_rmat_ren, //read enable,0: read disble 1:read enable
    input               chn0_up_en   ,
	input               chn0_mat_row_real_ok,
	input               chn0_mat_real_ok,
    output reg [3:0]    chn0_state_c ,
    output reg          chn0_col_end , 
    output reg          chn0_row_end , 
    output reg          chn0_frm_end , 
    output reg [6:0]    chn0_lmat_col,//0~127
    output reg [6:0]    chn0_lmat_row,//0~63
    output reg [6:0]    chn0_rmat_col,
    output reg [6:0]    chn0_rmat_row,
    
    //Channel1
    input               chn1_lmat_ok ,
    output				chn1_lmat_cs ,
    output              chn1_lmat_ren, 
    input               chn1_rmat_ok ,
    output reg          chn1_rmat_cs ,      
    output              chn1_rmat_ren, 
    input               chn1_up_en   ,
	input               chn1_mat_real_ok,
    output reg [3:0]    chn1_state_c ,
    output reg          chn1_col_end , 
    output reg          chn1_row_end , 
    output reg          chn1_frm_end , 
    output reg [6:0]    chn1_lmat_col,
    output reg [6:0]    chn1_lmat_row,
    output reg [6:0]    chn1_rmat_col,
    output reg [6:0]    chn1_rmat_row
);
    /*autowire*/
    reg chn0_lmat_ok_flag;
    reg chn0_rmat_ok_flag;
    reg chn1_lmat_ok_flag;
    reg chn1_rmat_ok_flag;
    reg [3:0]chn0_state_n;
    reg [3:0]chn1_state_n;
    reg mat_q_end;
    reg [6:0]chn0_lmat_col_max;
    reg [6:0]chn0_lmat_row_max;
    reg [6:0]chn0_rmat_col_max;
    reg [6:0]chn0_rmat_row_max;
    reg [6:0]chn1_lmat_col_max;
    reg [6:0]chn1_lmat_row_max;
    reg [6:0]chn1_rmat_col_max;
    reg [6:0]chn1_rmat_row_max;
    wire chn0_mat_rdy;
    wire chn1_mat_rdy;
    wire at_cal_en;
    wire sc_real_ok;
    wire s_ok;
    wire sc_ok;
    wire at_ok;
    // CH0 FSM0
    always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
            chn0_state_c <= IDEL;
        end
        else begin
            chn0_state_c <= chn0_state_n;
        end
    end
    //CHN0 FSM1
    always @(*)begin
        case(chn0_state_c)
            IDEL:begin
                if(chn0_mat_rdy)begin
                    chn0_state_n = CAL_QK;
                end
                else begin
                    chn0_state_n = chn0_state_c;
                end
            end
            CAL_QK:begin
                if(chn0_frm_end)begin
					chn0_state_n = WAIT_QK_DLY;
                end
                else begin
                    chn0_state_n = chn0_state_c;
                end
            end
            WAIT_QK_DLY:begin
				if(chn0_mat_real_ok)begin
					chn0_state_n = CAL_S;
            	end
            	else begin
            	    chn0_state_n = chn0_state_c;
            	end
            end
            CAL_S:begin
                if(chn0_frm_end)begin
					chn0_state_n = WAIT_S_DLY;
                end
                else begin
					chn0_state_n = chn0_state_c;
                end
            end
            WAIT_S_DLY:begin
				if(chn0_mat_real_ok)begin
					chn0_state_n = DENOMINTOR_SUM;
                end
                else begin
					chn0_state_n = chn0_state_c;
                end
            end
            DENOMINTOR_SUM:begin
                if(chn0_row_end)begin
					chn0_state_n = WAIT_DENOMINTOR_DLY;
                end
                else begin
					chn0_state_n = chn0_state_c;
                end
            end
            WAIT_DENOMINTOR_DLY:begin
                if(chn0_mat_row_real_ok)begin
					chn0_state_n = SOFT_MAX;
                end
                else begin
					chn0_state_n = chn0_state_c;
                end
            end
            SOFT_MAX:begin
                if(chn0_row_end)begin
					chn0_state_n = WAIT_SOFT_MAX_DLY;
				end
                else begin 
					chn0_state_n = chn0_state_c;
                end
            end
			WAIT_SOFT_MAX_DLY:begin
				if(chn0_mat_real_ok)begin
					chn0_state_n = WAIT_AV_DONE;
				end
				else if(chn0_mat_row_real_ok)begin
					chn0_state_n = DENOMINTOR_SUM;
				end
				else begin
					chn0_state_n = chn0_state_c;
				end
			end
            WAIT_AV_DONE:begin
                if(chn1_mat_rdy)begin
					chn0_state_n = WAIT_ATTENTION_DLY;
                end
                else begin
					chn0_state_n = chn0_state_c;
                end
            end
            WAIT_ATTENTION_DLY:begin
				if(chn1_state_c == WAIT_ATTENTION_DLY && chn1_mat_real_ok)begin
					chn0_state_n = IDEL;
				end
				else begin
					chn0_state_n = chn0_state_c;
				end
            end
            default:begin
                chn0_state_n = IDEL;
            end
        endcase
    end

    //CHN0 FSM2

	 always @(posedge clk or negedge rst_n)begin
   	     if(~rst_n)begin
   	         chn0_lmat_ok_flag <= 1'b0;
   	             end
   	     else if(chn0_lmat_ok)begin
   	         chn0_lmat_ok_flag <= 1'b1;
   	     end
   	     else if(chn0_mat_rdy)begin
   	         chn0_lmat_ok_flag <= 1'b0;
   	     end
   	 end

   	 always @(posedge clk or negedge rst_n)begin
   	 	if(~rst_n)begin
   	 	    chn0_rmat_ok_flag <= 1'b0;
   	 	        end
   	 	else if(chn0_rmat_ok)begin
   	 	    chn0_rmat_ok_flag <= 1'b1;
   	 	end
   	 	else if(chn0_mat_rdy)begin
   	 	    chn0_rmat_ok_flag <= 1'b0;
   	 	end
   	 end

	assign chn0_mat_rdy = chn0_state_c == IDEL ? chn0_lmat_ok_flag&chn0_rmat_ok_flag&chn1_lmat_ok_flag&chn1_rmat_ok_flag :
						  chn0_state_c == WAIT_QK_DLY ? 1'b1: 1'b0;//????
	
        
    //Channel0
	
	always @(*)begin
		case(chn0_state_c)
			CAL_QK,WAIT_QK_DLY:begin
				chn0_lmat_col_max = X_MAT_W/4-1 ;//127 
            	chn0_lmat_row_max = X_MAT_H-1   ;//63
            	chn0_rmat_col_max = W_MAT_W/4-1 ;//127 
            	//chn0_rmat_row_max = W_MAT_H/4-1 ;//15 
			end
			DENOMINTOR_SUM,WAIT_DENOMINTOR_DLY,SOFT_MAX,WAIT_SOFT_MAX_DLY:begin
				chn0_lmat_col_max = W_MAT_W/4-1 ;//15 
            	chn0_lmat_row_max = X_MAT_H-1   ;//63
            	chn0_rmat_col_max = 'd0;
            	//chn0_rmat_row_max = 'd0;
			end
			default:begin
				chn0_lmat_col_max = W_MAT_W/4-1 ;//15 
            	chn0_lmat_row_max = X_MAT_H-1   ;//63
            	chn0_rmat_col_max = W_MAT_W/4-1 ;//15 
            	//chn0_rmat_row_max = X_MAT_H/4-1 ;//15
			end
		endcase
    end

    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn0_lmat_col <= 7'd0;
        end
		else if(chn0_state_c == IDEL)begin
            chn0_lmat_col <= 7'd0;
		end
		else if(chn0_col_end&chn0_up_en)begin
    	    chn0_lmat_col <= 7'd0;
		end
		else if(chn0_up_en)begin
			chn0_lmat_col <= chn0_lmat_col+7'd1;
    	end
    end
   
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
			chn0_lmat_row <= 7'd0;
        end
		else if(chn0_state_c == IDEL)begin
			chn0_lmat_row <= 7'd0;
		end
		else if(chn0_frm_end&chn0_up_en)begin
			chn0_lmat_row <= 7'd0;
    	end
    	else if(chn0_row_end&chn0_up_en)begin
			chn0_lmat_row <= chn0_lmat_row + 7'd1;
    	end
    end

    always @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
			chn0_rmat_col <= 7'd0;
        end
		else begin
			case(chn0_state_c)
				CAL_QK,WAIT_QK_DLY,CAL_S,WAIT_S_DLY:begin
					if(chn0_row_end&chn0_up_en)begin
        			    chn0_rmat_col <= 7'd0;
        			end
        			else if(chn0_col_end&chn0_up_en)begin
        			    chn0_rmat_col <= chn0_rmat_col+7'd1;
        			end
				end
				default:begin
					chn0_rmat_col <= 7'd0;
				end
			endcase

		end
    end

    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn0_rmat_row <= 7'd0;
        end
		else begin
			case(chn0_state_c)
				CAL_QK,WAIT_QK_DLY,CAL_S,WAIT_S_DLY:begin
					if(chn0_col_end&chn0_up_en)begin
    				    chn0_rmat_row <= 7'd0;
    				end
    				else if(chn0_up_en)begin
    				    chn0_rmat_row <= chn0_rmat_row+7'd1;
    				end
				end
				default:begin
					chn0_rmat_row <= 7'd0;
				end
			endcase
		end
    end
    
    always@(*)begin
		chn0_col_end = chn0_lmat_col == chn0_lmat_col_max ? 1'b1 : 1'b0;
    end

    always@(*)begin
		chn0_row_end = (chn0_col_end == 1'b1 && chn0_rmat_col == chn0_rmat_col_max) ? 1'b1:1'b0;
    end

    always @(*)begin
		chn0_frm_end = (chn0_row_end == 1'b1 &&  chn0_lmat_row == chn0_lmat_row_max) ? 1'b1:1'b0;
    end
   
    assign chn0_lmat_ren = 1'b1;
    assign chn0_rmat_ren = 1'b1;
    always @(posedge clk or negedge rst_n)begin 
        if(~rst_n)begin                         
            chn0_lmat_cs <= 1'b0;    
        end                                     
		else begin
			case(chn0_state_c)
				IDEL:begin
					chn0_lmat_cs <= chn0_mat_rdy;
				end
				CAL_QK:begin
					if(chn0_lmat_cs)begin
						chn0_lmat_cs <= 1'b0;
					end
					else if(chn0_up_en)begin
						chn0_lmat_cs <= 1'b1;
					end
				end
				WAIT_QK_DLY:begin
					chn0_lmat_cs <= chn0_mat_real_ok;
				end
				CAL_S:begin
					if(chn0_lmat_cs)begin
						chn0_lmat_cs <= 1'b0;
					end
					else if(chn0_up_en)begin
						chn0_lmat_cs <= 1'b1;
					end
				end
				WAIT_S_DLY:begin
					chn0_lmat_cs <= chn0_mat_real_ok;
				end
				DENOMINTOR_SUM:begin
					if(chn0_row_end)begin
						chn0_lmat_cs <= 1'b0;
					end
				end
				WAIT_DENOMINTOR_DLY:begin
					chn0_lmat_cs <= chn0_mat_row_real_ok;
				end
				SOFT_MAX:begin
					if(chn0_row_end)begin
						chn0_lmat_cs <= 1'b0;
					end
				end
                WAIT_SOFT_MAX_DLY:begin
                    if(chn0_mat_row_real_ok)begin
					    if(chn0_mat_real_ok)begin
                            chn0_lmat_cs <= 1'b0; 
                        end
					    else begin
                            chn0_lmat_cs <= 1'b1; 
					    end
                    end
                end
                default:begin
                    chn0_lmat_cs <= 1'b0;
                end
			endcase
		end
    end

    always @(*)begin
        case(chn0_state_c)
            CAL_QK,WAIT_QK_DLY,CAL_S,WAIT_S_DLY:chn0_rmat_cs = chn0_lmat_cs;
            default:chn0_rmat_cs = 1'b0;
        endcase
    end

	//Channel1
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_state_c <= IDEL;
        end
        else begin
            chn1_state_c <= chn1_state_n;
        end
    end

    always @(*)begin
		case(chn1_state_c)
            IDEL:begin
				if(chn1_mat_rdy)begin
            	    chn1_state_n = CAL_QK;
            	end
            	else begin
            	    chn1_state_n = chn1_state_c;
            	end
			end
            CAL_QK:begin
				if(chn1_frm_end)begin
					chn1_state_n = CAL_S;
            	end
            	else begin
            	    chn1_state_n = chn1_state_c;
            	end
			end
            CAL_S:begin
				if(chn1_mat_rdy)begin
					chn1_state_n = CAL_V;
            	end
            	else begin
					chn1_state_n = chn1_state_c;
            	end
            end
            CAL_V:begin
				if(chn1_frm_end)begin
					chn1_state_n = WAIT_AV_DONE;
            	end
            	else begin
            	    chn1_state_n = chn1_state_c;
            	end
            end
            WAIT_AV_DONE:begin
				if(chn1_mat_rdy)begin
					chn1_state_n = ATTENTION;
            	end
            	else begin
					chn1_state_n = chn1_state_c;
            	end
            end
            ATTENTION:begin 
				if(chn1_frm_end)begin
					chn1_state_n = WAIT_ATTENTION_DLY;
				end
				else begin
					chn1_state_n = chn1_state_c;
				end
            end
            WAIT_ATTENTION_DLY:begin
				if(chn1_mat_real_ok)begin
					chn1_state_n = IDEL;
                end
                else begin
					chn1_state_n = chn1_state_c;
                end
            end
			default:begin
				chn1_state_n = IDEL;
			end
        endcase
	end

   	always @(posedge clk or negedge rst_n)begin
   	     if(~rst_n)begin
   	         chn1_lmat_ok_flag <= 1'b0;
   	             end
   	     else if(chn1_lmat_ok)begin
   	         chn1_lmat_ok_flag <= 1'b1;
   	     end
   	     else if(chn1_mat_rdy)begin
   	         chn1_lmat_ok_flag <= 1'b0;
   	     end
	 end

	 always @(posedge clk or negedge rst_n)begin
   	     if(~rst_n)begin
   	         chn1_rmat_ok_flag <= 1'b0;
   	             end
   	     else if(chn1_rmat_ok)begin
   	         chn1_rmat_ok_flag <= 1'b1;
   	     end
   	     else if(chn1_mat_rdy)begin
   	         chn1_rmat_ok_flag <= 1'b0;
   	     end
   	 end

	assign chn1_mat_rdy = chn1_state_c == IDEL  ? chn0_lmat_ok_flag&chn0_rmat_ok_flag&chn1_lmat_ok_flag&chn1_rmat_ok_flag : 
						  chn1_state_c == CAL_S ? chn1_lmat_ok_flag&chn1_rmat_ok_flag :
						  chn1_state_c == WAIT_AV_DONE ? chn1_lmat_ok_flag&chn1_rmat_ok_flag : 1'b0;

    always @(*)begin
        if(chn1_state_c == ATTENTION)begin
            chn1_lmat_col_max = X_MAT_H/4-1 ;//16 
            chn1_lmat_row_max = W_MAT_W-1   ;//64
            chn1_rmat_col_max = W_MAT_W/4-1 ;//16 
            //chn1_rmat_row_max = X_MAT_H/4-1 ;//16
        end
        else begin
            chn1_lmat_col_max = X_MAT_W/4-1 ; 
            chn1_lmat_row_max = X_MAT_H-1   ; 
            chn1_rmat_col_max = W_MAT_W/4-1 ; 
            //chn1_rmat_row_max = W_MAT_H/4-1 ; 
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_lmat_col <= 7'd0;
        end
		else if(chn1_state_c == IDEL)begin
            chn1_lmat_col <= 7'd0;
		end
        else if(chn1_col_end&chn1_up_en)begin
            chn1_lmat_col <= 7'd0;
        end
        else if(chn1_up_en)begin
            chn1_lmat_col <= chn1_lmat_col+7'd1;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_lmat_row <= 7'd0;
        end
		else if(chn1_state_c == IDEL)begin
            chn1_lmat_row <= 7'd0;
		end
        else if(chn1_frm_end&chn1_up_en)begin
            chn1_lmat_row <= 7'd0;
        end
        else if(chn1_row_end&chn1_up_en)begin
            chn1_lmat_row <= chn1_lmat_row+7'd1;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_rmat_col <= 7'd0;
        end
		else if(chn1_state_c == IDEL)begin
            chn1_rmat_col <= 7'd0;
		end
        else if(chn1_row_end&chn1_up_en)begin
            chn1_rmat_col <= 7'd0;
        end
        else if(chn1_col_end&chn1_up_en)begin
            chn1_rmat_col <= chn1_rmat_col+7'd1;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            chn1_rmat_row <= 7'd0;
        end
		else if(chn1_state_c == IDEL)begin
            chn1_rmat_row <= 7'd0;
		end
        else if(chn1_col_end&chn1_up_en)begin
            chn1_rmat_row <= 7'd0;
        end
        else if(chn1_up_en)begin
            chn1_rmat_row <= chn1_rmat_row+7'd1;
        end
    end

    always@(*)begin
		//case(chn1_state_c)
    	    //CAL_QK,CAL_V,ATTENTION:begin
				chn1_col_end = chn1_lmat_col == chn1_lmat_col_max ? 1'b1 : 1'b0;
    	   // end
    	    //default:begin
				//chn1_col_end = 1'b0;
    	    //end
    	//endcase
    end

    always@(*)begin
		chn1_row_end = (chn1_col_end == 1'b1 && chn1_rmat_col == chn1_rmat_col_max) ? 1'b1:1'b0;
    end

    always @(*)begin
		chn1_frm_end = (chn1_row_end == 1'b1 &&  chn1_lmat_row == chn1_lmat_row_max) ? 1'b1:1'b0;
    end

	assign chn1_lmat_cs = chn1_rmat_cs;
    always @(posedge clk or negedge rst_n)begin 
        if(~rst_n)begin                         
            chn1_rmat_cs <= 1'b0;
        end                                     
		else begin
			case(chn1_state_c)
				IDEL:begin
					chn1_rmat_cs <= chn1_mat_rdy;
				end
				CAL_QK:begin
					if(chn1_rmat_cs)begin
						chn1_rmat_cs <= 1'b0;
					end
					else if(chn1_up_en)begin
						chn1_rmat_cs <= 1'b1;
					end
				end
				CAL_S:begin
					if(chn1_mat_rdy)begin
						chn1_rmat_cs <= 1'b1;
            		end
            		else begin
						chn1_rmat_cs <= 1'b0;
            		end
				end
				CAL_V:begin
					if(chn1_rmat_cs)begin
						chn1_rmat_cs <= 1'b0;
					end
					else if(chn1_up_en|chn1_mat_rdy)begin
						chn1_rmat_cs <= 1'b1;
					end
				end
				WAIT_AV_DONE:begin
					chn1_rmat_cs <= chn1_mat_rdy;
				end
				ATTENTION:begin
					if(chn1_rmat_cs)begin
						chn1_rmat_cs <= 1'b0;
					end
					else if(chn1_up_en)begin
						chn1_rmat_cs <= 1'b1;
					end
				end
				default:begin
					chn1_rmat_cs <= 1'b0;
				end

			endcase
		end
    end

	assign chn1_lmat_ren = 1'b1;
	assign chn1_rmat_ren = 1'b1;
endmodule
