`default_nettype none 

module UARTTest(
	input RS232_Rx,
	input clk,
	output RS232_Tx,
	output led,
	output rxout
	);
	
	reg led_set;
	assign led = led_set;

	// Setup necessary for UART
   wire 			   reset = 0;
   reg 				   transmit;
   reg [7:0] 		   tx_byte;
   wire 			   received;
   wire [7:0] 		   rx_byte;
   wire 			   is_receiving;
   wire 			   is_transmitting;
   wire 			   recv_error;
   
   assign rxout = rx_byte[0] || rx_byte[7];

   // UART module, from https://github.com/cyrozap/osdvu
    uart uart0(
	    .clk(clk),                    // The master clock for this module
	    .rst(reset),                      // Synchronous reset
	    .rx(RS232_Rx),                // Incoming serial line
	    .tx(RS232_Tx),                // Outgoing serial line
	    .transmit(transmit),              // Signal to transmit
	    .tx_byte(tx_byte),                // Byte to transmit
	    .received(received),              // Indicated that a byte has been received
	    .rx_byte(rx_byte),                // Byte received
	    .is_receiving(is_receiving),      // Low when receive line is idle
	    .is_transmitting(is_transmitting),// Low when transmit line is idle
	    .recv_error(recv_error)           // Indicates error in receiving packet.
	    );
		
	always @(posedge clk) begin
		if (received)
			led_set <= rx_byte[0] || rx_byte[7];
	end
	
endmodule
		
	