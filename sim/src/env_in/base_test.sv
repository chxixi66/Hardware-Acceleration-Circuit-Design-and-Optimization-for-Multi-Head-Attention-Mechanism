class base_test extends uvm_test;
	env `DUT_TOP_NAME(env);
	function new(string name = "base_test",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("base_test","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task reset_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	extern virtual function void report_phase(uvm_phase phase);
	virtual function void set_override();
	endfunction

	`uvm_component_utils(base_test)
endclass

function void base_test::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("base_test","build_phase is called",UVM_LOW)
	`DUT_TOP_NAME(env) = env::type_id::create(`DUT_TOP_NAME_STR(env),this);
	uvm_config_db#(uvm_object_wrapper)::set(this,"transformer_env.transformer_in_agent.transformer_virtual_sequencer.main_phase","default_sequence",virtual_sequence::type_id::get());
	set_override();
endfunction

function void base_test::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("base_test","connect_phase is called",UVM_LOW)
endfunction

task base_test::reset_phase(uvm_phase phase);
	super.reset_phase(phase);
	`uvm_info("base_test","reset_phase is called",UVM_LOW)
endtask

task base_test::main_phase(uvm_phase phase);
	super.main_phase(phase);
	`uvm_info("base_test","main_phase is called",UVM_LOW)
endtask

function void base_test::report_phase(uvm_phase phase);
	int err_num;
	uvm_report_server server;
	super.report_phase(phase);
	`uvm_info("base_test","report_phase is called",UVM_LOW)
	server = get_report_server();
	err_num = server.get_severity_count(UVM_ERROR);
	if(err_num == 0)
		$display("\033[;32m=================TEST CASE PASSED=============\033[0m");
	else 
		$display("\033[;31m=================TEST CASE FAILED=============\031[0m");
endfunction
