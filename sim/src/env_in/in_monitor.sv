class in_monitor extends uvm_monitor;
	virtual clk_rst_if clk_if;
	virtual input_data_if in_if;
	uvm_analysis_port#(data_transaction) ap;
	function new(string name = "in_monitor",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("in_monitor","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	extern virtual task collect_one_pkg(input data_transaction tr);
	`uvm_component_utils(in_monitor)
endclass

function void in_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("in_monitor","build_phase is called",UVM_LOW)
	ap = new("ap",this);
endfunction

function void in_monitor::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("in_monitor","connect_phase is called",UVM_LOW)
	if(!uvm_config_db#(virtual clk_rst_if)::get(this,"","vif_clk_rst",clk_if))
		`uvm_fatal("in_monitor","virtual interface must be set for clk_if");
	if(!uvm_config_db#(virtual input_data_if)::get(this,"","vif_input_data",in_if))
		`uvm_fatal("in_monitor","virtual interface must be set for in_if");
endfunction

task in_monitor::main_phase(uvm_phase phase);
	data_transaction tr;
	verify_ctrl vc;
	super.main_phase(phase);
	`uvm_info("in_monitor","main_phase is called",UVM_LOW)
	uvm_resource_db#(verify_ctrl)::read_by_name("","verify_ctrl",vc);
	while(1)begin
		collect_one_pkg(tr);
		//ap.write(tr);
		//`uvm_info(get_type_name(),"in_monitor writed a data",UVM_LOW)
	end
endtask

task in_monitor::collect_one_pkg(input data_transaction tr);
	#5;
endtask
