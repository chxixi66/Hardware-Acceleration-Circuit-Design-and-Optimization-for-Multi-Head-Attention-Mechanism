class virtual_sequence extends uvm_sequence;
	data_sequence `DUT_TOP_NAME(data_sequence);
	`uvm_declare_p_sequencer(virtual_sequencer)
	function new(string name = "virtual_sequence");
		super.new(name);
		`uvm_info("virtual_sequence","new is called",UVM_LOW)
	endfunction
	virtual task body();
		`uvm_info("virtual_sequence","body is called",UVM_LOW)
		//if(starting_phase != null)begin
		//	starting_phase.raise_objection(this);
		//	$display("raise_objection");
		//end
		`uvm_create_on(`DUT_TOP_NAME(data_sequence),p_sequencer.`DUT_TOP_NAME(data_sequencer));
		`uvm_send(`DUT_TOP_NAME(data_sequence))
		//if(starting_phase != null)begin
		//	starting_phase.drop_objection(this);
		//	$display("drop_objection");
		//end
	endtask
	`uvm_object_utils(virtual_sequence)
endclass
