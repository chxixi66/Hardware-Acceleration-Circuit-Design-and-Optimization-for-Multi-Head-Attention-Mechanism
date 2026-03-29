interface clk_rst_if();
	logic clk;
	logic rst_n;

	initial begin
		clk <= 0;
		forever begin
			#5 clk <= ~clk;
		end
	end
endinterface
