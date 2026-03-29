class in_agent extends uvm_agent;
	data_sequencer `DUT_TOP_NAME(data_sequencer);
	virtual_sequencer `DUT_TOP_NAME(virtual_sequencer);
	data_driver `DUT_TOP_NAME(data_driver);
	in_monitor `DUT_TOP_NAME(in_monitor);
	function new(string name = "in_agent",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("in_agent","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	`uvm_component_utils(in_agent)
endclass

function void in_agent::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("in_agent","build_phase is called",UVM_LOW)
	`DUT_TOP_NAME(virtual_sequencer) = virtual_sequencer::type_id::create(`DUT_TOP_NAME_STR(virtual_sequencer),this);
	`DUT_TOP_NAME(data_sequencer) = data_sequencer::type_id::create(`DUT_TOP_NAME_STR(data_sequencer),this);
	`DUT_TOP_NAME(data_driver) = data_driver::type_id::create(`DUT_TOP_NAME_STR(data_driver),this);
	`DUT_TOP_NAME(in_monitor) = in_monitor::type_id::create(`DUT_TOP_NAME_STR(in_monitor),this);
endfunction

function void in_agent::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("in_agent","connect_phase is called",UVM_LOW)
	`DUT_TOP_NAME(virtual_sequencer).`DUT_TOP_NAME(data_sequencer) = `DUT_TOP_NAME(data_sequencer);
	`DUT_TOP_NAME(data_driver).seq_item_port.connect(`DUT_TOP_NAME(data_sequencer).seq_item_export);
endfunction

task in_agent::main_phase(uvm_phase phase);
	super.main_phase(phase);
	`uvm_info("in_agent","main_phase is called",UVM_LOW)
endtask
