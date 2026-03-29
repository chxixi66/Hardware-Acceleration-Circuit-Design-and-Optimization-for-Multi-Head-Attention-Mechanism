initial begin
	if($test$plusargs("DUMP_FSDB"))begin
		$fsdbDumpfile("tb.fsdb");//waveform name
		$fsdbDumpvars(0,testbench);
		$fsdbDumpMDA();
		$fsdbDumpSVA();
		$display("dump wave is on");
	end
end
