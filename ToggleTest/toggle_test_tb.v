`default_nettype none
`timescale 1ns / 100ps

module tb;

	reg clk = 0;
	wire outpin;

	toggle_test uut(
		.clk(clk),
		.outpin(outpin)
	);
	
	initial begin
      $dumpfile("Sim/toggle_test_tb.vcd");
      $dumpvars(0, uut);

      clk = 1'b0;
	  #10000000 $finish;
	end
	
	always begin
      #2.5 clk <= ~clk;
   end

endmodule