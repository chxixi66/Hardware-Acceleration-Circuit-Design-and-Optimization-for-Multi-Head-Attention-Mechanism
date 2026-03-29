`include "uvm_macros.svh"
`include "uvm_pkg.sv"
`include "coverage.sv"
import uvm_pkg::*;
module testbench();
	clk_rst_if clk_if();
	parameter DATA_WIDTH = 16;
	parameter HEADER_NUM = 8 ;
	parameter DATA_NUM   = 4 ;
	input_data_if#(
		.DATA_WIDTH(DATA_WIDTH),
		.HEADER_NUM(HEADER_NUM),
		.DATA_NUM  (DATA_NUM)
	) in_if();

	output_data_if #(
		.DATA_WIDTH(DATA_WIDTH)
	)out_if();

	TRANSFORMER#(
		.DATA_WIDTH (DATA_WIDTH),
	    .HEADER_NUM (HEADER_NUM),
		.DATA_NUM   (DATA_NUM  ) 
	)TRANSFORMER(
		.clk        ( clk_if.clk        ) ,
		.rst_n      ( clk_if.rst_n      ) ,
    
		//X Channel
		.x_ok       ( in_if.x_ok       ) ,
		.x_ren      ( in_if.x_ren      ) ,
		.x_cs       ( in_if.x_cs       ) ,
		.x_rd_addr  ( in_if.x_rd_addr  ) ,
		.x          ( in_if.x          ) ,
    
		//Q Channel
		.wq_ok      ( in_if.wq_ok      ) ,
		.wq_ren     ( in_if.wq_ren     ) ,
		.wq_cs      ( in_if.wq_cs      ) ,
		.wq_rd_addr ( in_if.wq_rd_addr ) ,
		.wq         ( in_if.wq         ) ,
		.wq_bit_map ( in_if.wq_bit_map ) ,
        
		//K Channel
		.wk_ok      ( in_if.wk_ok      ) ,
		.wk_ren     ( in_if.wk_ren     ) ,
		.wk_cs      ( in_if.wk_cs      ) ,
		.wk_rd_addr ( in_if.wk_rd_addr ) ,
		.wk         ( in_if.wk         ) ,
		.wk_bit_map ( in_if.wk_bit_map ) ,
        
		//V Channel
		.wv_ok      ( in_if.wv_ok      ) ,
		.wv_ren     ( in_if.wv_ren     ) ,
		.wv_cs      ( in_if.wv_cs      ) ,
		.wv_rd_addr ( in_if.wv_rd_addr ) ,
		.wv         ( in_if.wv         ) ,
		.wv_bit_map ( in_if.wv_bit_map ) ,
        
		//OUTPUT
		.attention_vld( out_if.attention_vld),
		.attention0   ( out_if.attention0   ) ,
		.attention1   ( out_if.attention1   ) ,
		.attention2   ( out_if.attention2   ) ,
		.attention3   ( out_if.attention3   ) ,
		.attention4   ( out_if.attention4   ) ,
		.attention5   ( out_if.attention5   ) ,
		.attention6   ( out_if.attention6   ) ,
		.attention7   ( out_if.attention7   ) 
	);

	initial begin
		uvm_config_db#(virtual clk_rst_if)::set(null,"uvm_test_top.transformer_env.transformer_in_agent.transformer_data_driver","vif_clk_rst",clk_if);
		uvm_config_db#(virtual input_data_if)::set(null,"uvm_test_top.transformer_env.transformer_in_agent.transformer_data_driver","vif_input_data",in_if);

		uvm_config_db#(virtual clk_rst_if)::set(null,"uvm_test_top.transformer_env.transformer_in_agent.transformer_in_monitor","vif_clk_rst",clk_if);
		uvm_config_db#(virtual input_data_if)::set(null,"uvm_test_top.transformer_env.transformer_in_agent.transformer_in_monitor","vif_input_data",in_if);

		uvm_config_db#(virtual clk_rst_if)::set(null,"uvm_test_top.transformer_env.transformer_out_agent.transformer_out_monitor","vif_clk_rst",clk_if);
		uvm_config_db#(virtual output_data_if)::set(null,"uvm_test_top.transformer_env.transformer_out_agent.transformer_out_monitor","vif_output_data",out_if);
	end
	
	`include "dump_wave.sv"
	`include "run_test.sv"

	coverage u_coverage(clk_if,in_if,out_if);
endmodule
//Local Variables:
//verilog-library-directories:(".")
//verilog-library-directories-recursive:1
//End:
