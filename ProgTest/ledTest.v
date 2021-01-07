`default_nettype none
module ledTest(
	input clk,
	input sw,
	output led
	);
	
	assign led = sw;
endmodule