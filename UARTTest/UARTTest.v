`default_nettype none 

module UARTTest(
	input RS232_Rx,
	input clk,
	output RS232_Tx,
	output led,
	output rxout1,
	output rxout2
	);

	// Setup necessary for UART
   wire 			   reset = 0;
   reg 				   transmit = 1;
   reg [7:0] 		   tx_byte;
   wire 			   received;
   wire [7:0] 		   rx_byte;
   wire 			   is_receiving;
   wire 			   is_transmitting;
   wire 			   recv_error;
   reg [7:0]		   transmitbyte = 8'd130; //tried 8'd65 for A but might have gotten endianness wrong, trying 8'd130 (reverse of 65)
   reg				   txstate = 0;

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
	
	/*//using alternate UART, from https://github.com/gromero/ecp5
	wire		reset = 0;
	reg [7:0]   rx_byte, tx_byte;
	reg [1:0]	addr;
	wire		we, clk, cs, probe0, ack;
	
	//using alternate UART, from https://github.com/gromero/ecp5
	uart uart0(
		.clk(clk),
		.reset(reset),
		.rx_bit(RS232_Rx),
		.tx_bit(RS232_Tx),
		.wb_data_in(rx_byte),
		.wb_data_out(tx_byte),
		.wb_addr(addr),
		.wb_we(we),             
		.wb_clk(clk),           
		.wb_stb(cs),           
		.probe0(probe0),       
		.wb_ack(ack)
	);*/
	
	//testing received values
	assign rxout1 = received;
	assign rxout2 = is_receiving;
	assign led = received;
	
	/*//testing transmitted values
	assign rxout1 = is_transmitting;
	assign led = is_transmitting;
	
	always @(posedge clk) begin
		tx_byte <= transmitbyte;
		if (txstate) begin
			transmit <= 1;
			txstate <= 0;
		end
		else begin
			transmit <=0;
			txstate <= 1;
		end
	end*/
	
endmodule
		
	