`default_nettype none
module toggle_test(
	input clk,
	output outpin
	);
	
	reg out;
	reg [31:0] count = 0;
	wire clk_pll, lock;
	
	assign outpin = out;
	
	pll ecppll(
	    .clock_in(clk),
        .clock_out(clk_pll),
	    .locked(lock)
	    );
	
	always @(posedge clk_pll) begin	
		out <= (count < 100000) ? 0 : 1;
		count <= (count == 200000) ? 0 : count + 1;
	end
	
endmodule