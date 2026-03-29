class score_board extends uvm_scoreboard;
	uvm_blocking_get_port#(data_transaction) rm_port;
	uvm_blocking_get_port#(data_transaction) out_port;
	function new(string name = "score_board",uvm_component parent = null);
		super.new(name,parent);
		`uvm_info("score_board","new is called",UVM_LOW)
	endfunction	
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
	`uvm_component_utils(score_board)
endclass

function void score_board::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info("score_board","build_phase is called",UVM_LOW)
	rm_port = new("rm_port",this);
	out_port = new("out_port",this);
endfunction

function void score_board::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	`uvm_info("score_board","connect_phase is called",UVM_LOW)
endfunction

task score_board::main_phase(uvm_phase phase);
	verify_ctrl vc;
	data_transaction rm_tr;
	data_transaction out_tr;
	int comp_times = 0;
	super.main_phase(phase);
	`uvm_info("score_board","main_phase is called",UVM_LOW)
	uvm_resource_db#(verify_ctrl)::read_by_name("","verify_ctrl",vc);
	phase.raise_objection(this);
	fork 
		while(1)begin
			fork
				//rm_port.get(rm_tr);
				out_port.get(out_tr);
			join 
			//if(rm_tr.send_data == out_tr.mon_data[8:1])begin
			//	`uvm_info(get_type_name(),$sformatf("compare success!!!,send data:%b\trecv data:%b",rm_tr.send_data,out_tr.mon_data[8:1]),UVM_LOW)
			//end	
			//else begin
			//	`uvm_error(get_type_name(),$sformatf("compare  failue!!!,send data:%b\trecv data:%b",rm_tr.send_data,out_tr.mon_data[8:1]))
			//end
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention0(dut):%h,attention0(rm):%g",out_tr.attention0,out_tr.attention0),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention1(dut):%h,attention1(rm):%g",out_tr.attention1,out_tr.attention1),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention2(dut):%h,attention2(rm):%g",out_tr.attention2,out_tr.attention2),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention3(dut):%h,attention3(rm):%g",out_tr.attention3,out_tr.attention3),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention4(dut):%h,attention4(rm):%g",out_tr.attention4,out_tr.attention4),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention5(dut):%h,attention5(rm):%g",out_tr.attention5,out_tr.attention5),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention6(dut):%h,attention6(rm):%g",out_tr.attention6,out_tr.attention6),UVM_LOW)
			`uvm_info(get_type_name(),$sformatf("compare success!!!,attention7(dut):%h,attention7(rm):%g",out_tr.attention7,out_tr.attention7),UVM_LOW)
			comp_times++;
			if(comp_times == vc.data_num)
				break;
		end
	join_any
	phase.drop_objection(this);
endtask
