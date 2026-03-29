initial begin
	string tc_name = "";
	$value$plusargs("UVM_TESTNAME=%s",tc_name);
	run_test(tc_name);
end
