`default_nettype none
module clock_test(
	input clk,
	output out,
	output outpll
	);
	
	wire lock;
	
	pll ecppll(
	    .clock_in(clk),
        .clock_out(outpll),
	    .locked(lock)
	    );
		
	assign out = clk;
	
endmodule