`default_nettype none
module led_counter(
	input clk,
	output [7:0] led
	);
	
	reg [7:0] count = 0;
	reg [31:0] timer = 0;
	
	assign led = count;
	
	always @(posedge clk) begin
		timer <= timer + 1;
		if (timer == 12000000) begin
			timer <= 0;
			if (count == 255)
				count <= 0;
			else
				count <= count + 1;
		end
	end
endmodule	