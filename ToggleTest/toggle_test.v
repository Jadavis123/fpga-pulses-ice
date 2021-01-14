`default_nettype none
module toggle_test(
	input clk,
	output outpin,
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
		
	always @(posedge clk) begin	
		out <= (count == 12000) ? ~out : out;
		count <= (count == 12000) ? 0 : count + 32'b1;
	end
	
endmodule