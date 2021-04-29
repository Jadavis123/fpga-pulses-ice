`default_nettype none
module clock_test(
	input clk,
	output out
	);
	
	reg clk_pll, pulses;
	reg recv_out = 0;
	reg [31:0] counter = 0;
	wire lock;
	
	pll ecppll(
	    .clock_in(clk),
        .clock_out(clk_pll),
	    .locked(lock)
	    );
		
	assign out = recv_out;
	
	parameter width = 30; // .5 us pulse
	parameter delay = 200; // 1 us delay
	parameter period = 200000; //1 ms period
	
	parameter p2start = width + delay;
	parameter p2end = p2start + 2*width;
	
	always @(posedge clk_pll) begin
		/*case (counter)
		0 : begin
			pulses <= 1;
		end
		width : begin
			pulses <= 0;
		end
		p2start : begin
			pulses <= 1;
		end
		p2end: begin
			pulses <= 0;
		end
		endcase*/
		counter <= (counter < period) ? counter + 1 : 0;
		recv_out <= 1;
	end
	
endmodule