`default_nettype none
  module pulse_control(
		       input 	     clk,
		       input 	     RS232_Rx,
		       output 	     RS232_Tx,
		       output [31:0] del,
		       output [31:0] per,
		       output [31:0] s_up,
		       output [31:0] p1wid,
		       output [31:0] p2st,
		       output [31:0] p2wid,
		       output [31:0] pbwid,
		       output [31:0] att_d,
		       output [31:0] offr_d,
		       output [6:0]  pp_pu,
		       output [6:0]  pp_pr,
		       output 	     pu,
		       output 	     doub,
		       output [6:0]  p_att,
		       output [7:0]  p_bl,
		       output 	     bl
		       );

   // Control the pulses

   // Running at a 200-MHz clock, our time step is 5 ns.
   // All the times are thus divided by 5 ns to get cycles.
   // 32-bit allows times up to 21 seconds
   parameter stperiod = 32'd200000; // 1 ms period
   parameter stp1width = 32'd30; // 150 ns
   parameter stp2width = 32'd30;
   parameter stdelay = 32'd200; // 1 us delay
   parameter stp2start = stp1width + stdelay;
   parameter stsync_up = stp2start + stp2width;
   // The attenuator pulse switches down 10 us after the sync pulse,
   // because when it turns off there is a burst of noise, and this
   // moves that noise well after the signal
   parameter att_delay = 32'd20000;
   parameter statt_down = stsync_up + att_delay;
   parameter stpump = 1; // The pump is on by default
   
   reg [31:0] 		    period = stperiod;
   reg [31:0] 		    p1width = stp1width;
   reg [31:0] 		    p2width = stp2width;
   reg [31:0] 		    pbwidth = stp1width;
   reg [31:0] 		    delay = stdelay;
   reg [31:0] 		    p2start = stp2start;
   reg [31:0] 		    sync_up = stsync_up;
   reg [31:0] 		    att_down = statt_down;
   reg 			    pump = stpump;
   reg 			    double = 0;
   reg 			    block = 1;
   reg [7:0] 		    pulse_block = 8'd50;
   
   // Optionally put a pi/2 pulse 5 us before the first pi/2 pulse
   // to eliminate the echo for background subtraction
   parameter stoff = 32'd8000;
   reg [31:0] 		   offres_delay = stperiod - stoff - stp1width;
   
   // Control the attenuators
   parameter att_on_val = 7'd1;
   parameter att_off_val = 7'd0;
   reg [6:0] 		    pp_pump = att_off_val;
   reg [6:0] 		    pp_probe = att_on_val;
   reg [6:0] 		    post_att = att_off_val;

   assign per = period;
   assign p1wid = p1width;
   assign p2wid = p2width;
   assign pbwid = pbwidth;
   assign del = delay;
   assign p2st = p2start;
   assign s_up = sync_up;
   assign att_d = att_down;
   assign offr_d = offres_delay;
   assign pu = pump;
   assign doub = double;
   assign pp_pu = pp_pump;
   assign pp_pr = pp_probe;
   assign p_att = post_att;
   assign p_bl = pulse_block;
   assign bl = block;
   
      // Setup necessary for UART
   wire 		   reset = 0;
   reg 			   transmit;
   reg [7:0] 		    tx_byte;
   wire 		   received;
   wire [7:0] 		   rx_byte;
   wire 		   is_receiving;
   wire 		   is_transmitting;
   wire 		   recv_error;

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

   // input and output to be communicated
   reg [31:0] 		   vinput;  // input and output are reserved keywords
   reg [7:0] 		   vcontrol; // Control byte, the MSB (most significant byte) of the transmission
   reg [7:0] 		   voutput;
   reg [7:0] 		   vcheck; // Checksum byte; the input bytes are summed and sent back as output

   // Change the offset delay from 5 ns to 640 ns increments.
   // reg [22:0] 		   off_full_delay = 0;
   
   // We need to receive multiple bytes sequentially, so this sets up both
   // reading and writing. Adapted from the uart-adder from
   // https://github.com/cyrozap/iCEstick-UART-Demo/pull/3/files
   parameter read_A                 = 1'd0;
   parameter read_wait              = 1'd1;
   parameter write_A                = 1'd0;
   parameter write_done             = 1'd1;

   reg 			   writestate = write_A;
   reg [5:0] 		   writecount = 0;
   reg [1:0] 		   readstate = read_A;
   reg [5:0] 		   readcount = 0;

   parameter STATE_RECEIVING   = 2'd0;
   parameter STATE_CALCULATING = 2'd1;
   parameter STATE_SENDING     = 2'd2;

   // These set the behavior based on the control byte
   parameter CONT_SET_DELAY = 8'd0;
   parameter CONT_SET_PERIOD = 8'd1;
   parameter CONT_SET_PUMP = 8'd2;
   parameter CONT_SET_PROBE = 8'd3;
   parameter CONT_TOGGLE_PUMP = 8'd4;
   parameter CONT_SET_BACKPULSE = 8'd5;
   parameter CONT_SET_ATT = 8'd6;

   reg [2:0] 		   state = STATE_RECEIVING;

      // The communication runs at the 12 MHz clock rather than the 200 MHz clock.
   always @(posedge clk) begin
      
      case (state) 
	
        STATE_RECEIVING: begin
           transmit <= 0;
	   case (readstate)
	     read_A: begin
		if(received) begin
		   if(readcount == 6'd32) begin // Last byte in the transmission
		      vcontrol <= rx_byte;
		      state<=STATE_CALCULATING;
		      readcount <= 0;
		      readstate <= read_A;
		   end
		   else begin // Read the first bytes into vinput
		      vinput[readcount +: 8]=rx_byte;
		      readcount = readcount + 8;
		      readstate <= read_wait;
		   end
		end
	     end // case: read_A

	     read_wait: begin // Wait for the next byte to arrive
		if(~received) begin
		   readstate <= read_A;
		end
	     end
	   endcase // case (readstate)
	end // case: STATE_RECEIVING

	// Based on the control byte, assign a new value to the desired pulse parameter
        STATE_CALCULATING: begin
           writestate   <= write_A;
	   vcheck = vinput[31:24] + vinput[23:16] + vinput[15:8] + vinput[7:0];
	   case (vcontrol)

	     CONT_SET_DELAY: begin
		delay <= vinput;
		voutput <= vcheck;
	     end

	     CONT_SET_PERIOD: begin
		period <= vinput;
		voutput <= vcheck;
	     end

	     CONT_SET_PUMP: begin
		p1width <= vinput;
	     end

	     CONT_SET_PROBE: begin
		p2width <= vinput;
		voutput <= vcheck;
	     end

	     CONT_TOGGLE_PUMP: begin
		pump <= vinput[0];
		double <= vinput[1];
		block <= vinput[2];
		pulse_block <= vinput[15:8];
		// off_full_delay[22:7] <= vinput[31:16];
		// offres_delay <= period - off_full_delay;
		offres_delay <= period - (vinput[31:16] << 7);
		voutput <= vcheck;
	     end

	     CONT_SET_ATT: begin
		pp_probe <= vinput[7:0];
		post_att <= vinput[15:8];
		pp_pump <= vinput[23:16];
		voutput <= vcheck;
	     end

	     CONT_SET_BACKPULSE: begin
		pbwidth <= vinput;
		voutput <= vcheck;
	     end
	     
	   endcase // case (vcontrol)
//           state <= STATE_SENDING;
           state <= STATE_RECEIVING;
        end

        /*
	 * STATE_SENDING: begin


           case (writestate)

	     write_A: begin
		if (~ is_transmitting) begin
                   transmit <= 1;
		   writestate  <= write_done;
                   tx_byte <= voutput;
                   state     <= STATE_SENDING;
		end
	     end

	     write_done: begin
		if (~ is_transmitting) begin
                   writestate <= write_A; 
                   state     <= STATE_RECEIVING;
                   transmit <= 0;
		end
	     end

           endcase

        end
	 */

        default: begin
           // should not be reached
           state     <= STATE_RECEIVING;
           readcount <= read_A;
        end

      endcase // case (state)

      // After each change, update the pulse parameters
      p2start <= p1width + delay;
      sync_up <= p2start + p2width;   
      att_down <= sync_up + att_delay;
      
    end // always @ (posedge iCE_CLK)
endmodule // pulse_control