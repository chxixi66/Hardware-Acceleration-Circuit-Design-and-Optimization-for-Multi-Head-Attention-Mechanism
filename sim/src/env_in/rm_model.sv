class rm_model extends uvm_component;
	uvm_analysis_port#(data_transaction) ap;
	function new(string name = "rm_model",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("rm_model","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	`uvm_component_utils(rm_model)
endclass

function void rm_model::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("rm_model","build_phase is called",UVM_LOW)
	ap = new("ap",this);
endfunction

function void rm_model::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("rm_model","connect_phase is called",UVM_LOW)
endfunction

task rm_model::main_phase(uvm_phase phase);
	data_transaction tr;
	uvm_event ev_write_finish = uvm_event_pool::get_global("ev_write_finish");
	super.main_phase(phase);
	`uvm_info("rm_model","main_phase is called",UVM_LOW)
	ev_write_finish.wait_trigger();
	tr = new("tr");
	ap.write(tr);
endtask
