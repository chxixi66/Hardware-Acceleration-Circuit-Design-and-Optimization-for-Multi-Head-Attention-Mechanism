class out_monitor extends uvm_monitor;
	virtual clk_rst_if clk_if;
	virtual output_data_if out_if;
	verify_ctrl vc;
	uvm_analysis_port#(data_transaction) ap;
	function new(string name = "out_monitor",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("out_monitor","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task reset_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	extern virtual task collect_one_pkg(data_transaction tr);
	`uvm_component_utils(out_monitor)
endclass

function void out_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("out_monitor","build_phase is called",UVM_LOW)
	ap = new("ap",this);
endfunction

function void out_monitor::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("out_monitor","connect_phase is called",UVM_LOW)
 	uvm_resource_db#(verify_ctrl)::read_by_name("","verify_ctrl",vc);
	if(!uvm_config_db#(virtual clk_rst_if)::get(this,"","vif_clk_rst",clk_if))
		`uvm_fatal("out_monitor","virtual interface must be set for clk_if")
	if(!uvm_config_db#(virtual output_data_if)::get(this,"","vif_output_data",out_if))
		`uvm_fatal("out_monitor","virtual interface must be set for out_if")
endfunction

task out_monitor::reset_phase(uvm_phase phase);
	super.reset_phase(phase);
	`uvm_info("out_monitor","reset_phase is called",UVM_LOW)
endtask

task out_monitor::main_phase(uvm_phase phase);
	int run_times = 0;
	data_transaction tr;
	super.main_phase(phase);
	`uvm_info("out_monitor","main_phase is called",UVM_LOW)
	while(1)begin
		tr = new("tr");
		collect_one_pkg(tr);
		ap.write(tr);
	end
endtask

task out_monitor::collect_one_pkg(data_transaction tr);
	while(1)begin
		@(posedge clk_if.clk);
		if(out_if.attention_vld)begin
			tr.attention0 = out_if.attention0;
			tr.attention1 = out_if.attention1;
			tr.attention2 = out_if.attention2;
			tr.attention3 = out_if.attention3;
			tr.attention4 = out_if.attention4;
			tr.attention5 = out_if.attention5;
			tr.attention6 = out_if.attention6;
			tr.attention7 = out_if.attention7;
			break;
		end
	end
endtask
