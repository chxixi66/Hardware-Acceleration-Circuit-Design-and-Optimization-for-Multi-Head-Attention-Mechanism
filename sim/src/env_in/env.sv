class env extends uvm_env;
	in_agent `DUT_TOP_NAME(in_agent);
	out_agent `DUT_TOP_NAME(out_agent);
	rm_model `DUT_TOP_NAME(rm_model);
	score_board `DUT_TOP_NAME(score_board);
	verify_ctrl vc;
	uvm_tlm_analysis_fifo#(data_transaction) rm_fifo;
	uvm_tlm_analysis_fifo#(data_transaction) out_fifo;
	function new(string name = "env",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("env","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	`uvm_component_utils(env)
endclass

function void env::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("env","build_phase is called",UVM_LOW)
	`DUT_TOP_NAME(in_agent) = in_agent::type_id::create(`DUT_TOP_NAME_STR(in_agent),this);
	`DUT_TOP_NAME(out_agent) = out_agent::type_id::create(`DUT_TOP_NAME_STR(out_agent),this);
	`DUT_TOP_NAME(rm_model) = rm_model::type_id::create(`DUT_TOP_NAME_STR(rm_model),this);
	`DUT_TOP_NAME(score_board) = score_board::type_id::create(`DUT_TOP_NAME_STR(score_board),this);
	vc = verify_ctrl::type_id::create("vc");
	rm_fifo = new("rm_fifo",this);
	out_fifo = new("out_fifo",this);
	vc.randomize();
	uvm_resource_db#(verify_ctrl)::set("","verify_ctrl",vc);
endfunction

function void env::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("env","connect_phase is called",UVM_LOW)
	`DUT_TOP_NAME(in_agent).`DUT_TOP_NAME(in_monitor).ap.connect(rm_fifo.analysis_export);
	`DUT_TOP_NAME(out_agent).`DUT_TOP_NAME(out_monitor).ap.connect(out_fifo.analysis_export);
	`DUT_TOP_NAME(score_board).rm_port.connect(rm_fifo.blocking_get_export);
	`DUT_TOP_NAME(score_board).out_port.connect(out_fifo.blocking_get_export);
endfunction
