`default_nettype none
module toggle_test(
	input clk,
	output outpin
	);
	
	reg out = 0;
	reg [31:0] count = 0;
	wire clk_pll, lock;
	
	assign outpin = out;
	
	pll ecppll(
	    .clock_in(clk),
        .clock_out(clk_pll),
	    .locked(lock)
	    );
	
	always @(posedge clk_pll) begin	
		out <= (count < 200000) ? 1'b0 : 1'b1;
		count <= (count == 400000) ? 0 : count + 32'd1;
	end
	
endmodule