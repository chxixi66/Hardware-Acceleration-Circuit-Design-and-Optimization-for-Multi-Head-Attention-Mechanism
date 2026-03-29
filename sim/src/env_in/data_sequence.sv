class data_sequence extends uvm_sequence#(data_transaction);
	data_transaction tr;
	verify_ctrl vc;
	function new(string name = "data_sequence");
		super.new(name);
		`uvm_info("data_sequence","new is called",UVM_LOW)
	endfunction	
	extern task body();
	`uvm_object_utils(data_sequence)
endclass

task data_sequence::body();
	`uvm_info("data_sequence","body is called",UVM_LOW)
	uvm_resource_db#(verify_ctrl)::read_by_name("","verify_ctrl",vc);
	for(int i = 0; i < vc.data_num; i++)begin
		`uvm_create(tr);
		tr.randomize();
		`uvm_send(tr);
	end
	`uvm_info(get_type_name(),"data_sequence send datas finish",UVM_LOW)
endtask
