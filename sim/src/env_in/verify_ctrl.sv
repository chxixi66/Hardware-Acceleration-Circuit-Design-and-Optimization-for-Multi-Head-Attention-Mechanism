class verify_ctrl extends uvm_object;
	rand byte data_num;
	constraint  data_num_cons{
		data_num inside {[0:15]};
		data_num == 2;
    }

	function new(string name="verify_ctrl");
		super.new(name);
		`uvm_info(get_type_name(),"new is called",UVM_LOW)
	endfunction	

	function void post_randomize();
		`uvm_info(get_type_name(),$sformatf("data_num :%d",data_num),UVM_LOW)
	endfunction

	`uvm_object_utils_begin(verify_ctrl)
		`uvm_field_int(data_num,UVM_ALL_ON)
	`uvm_object_utils_end
endclass
