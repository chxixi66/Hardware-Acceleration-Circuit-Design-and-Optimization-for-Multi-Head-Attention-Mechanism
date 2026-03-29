class out_agent extends uvm_agent;
	out_monitor	`DUT_TOP_NAME(out_monitor);
	function new(string name = "out_agent",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("out_agent","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	`uvm_component_utils(out_agent)
endclass

function void out_agent::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("out_agent","build_phase is called",UVM_LOW)
	`DUT_TOP_NAME(out_monitor) = out_monitor::type_id::create(`DUT_TOP_NAME_STR(out_monitor),this);
endfunction

function void out_agent::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("out_agent","connect_phase is called",UVM_LOW)
endfunction

task out_agent::main_phase(uvm_phase phase);
	super.main_phase(phase);
	`uvm_info("out_agent","main_phase is called",UVM_LOW)
endtask
