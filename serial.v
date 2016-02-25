module serial # (
	parameter CLK_RATE = 100000000,
	parameter BAUD_RATE = 115200
) (
	input clk,
	input rx,
	output tx,
	output new_block,
	output [351:0] block,
	input result_ready,
	input [31:0] result_in
);

	// Registers To Process Block Data
	reg block_data_ready = 1'b0;
	reg [351:0] block_data = 352'd0;
	
	assign new_block = block_data_ready;
	assign block = block_data;

	// Registers To Process Results
	reg send_msg = 1'b0;
	reg send_result = 1'b0;
	reg [31:0] result = 32'd0;

	reg [31:0] tx_msg_data = 32'd0;
	reg tx_msg_ready = 1'b0;
	wire tx_busy;

	write_msg # (.CLK_RATE(CLK_RATE), .BAUD_RATE(BAUD_RATE)) write_msg (
		.clk(clk),
		.tx(tx),
		.msg_data(tx_msg_data),
		.msg_ready(tx_msg_ready),
		.busy(tx_busy)
	);

	wire [7:0] rx_msg_len;
	wire [351:0] rx_msg_data;
	wire rx_msg_ready;

	read_msg # (.CLK_RATE(CLK_RATE), .BAUD_RATE(BAUD_RATE)) read_msg (
		.clk(clk),
		.rx(rx),
		.rx_msg_len(rx_msg_len),
		.rx_msg_data(rx_msg_data),
		.rx_msg_ready(rx_msg_ready)
	);

 	always @(posedge clk) begin

		block_data_ready = 1'b0;
		tx_msg_ready = 1'b0;

		// When Serial Is Idle, Send Results
		if ( !send_msg && !rx_msg_ready && !tx_busy ) begin

			// Send Result
			if ( send_result ) begin

				tx_msg_data = result;
				send_msg = 1'b1;
				send_result = 1'b0;
				
			end
			else if ( result_ready ) begin
			
				result = result_in;
				send_result = 1'b1;
				
			end

		end

		// Process Outgoing Messages
		if ( send_msg && !tx_busy ) begin

			tx_msg_ready = 1'b1;		
			send_msg = 1'b0;

		end

		// Process Incoming Messages
		if ( rx_msg_ready ) begin

			if ( rx_msg_len == 10'd44 ) begin  // 32 Bytes Midstate + 12 Bytes Remaining Block Data
				block_data = rx_msg_data;
				block_data_ready = 1'b1;
			end

		end

	end
	
endmodule


module read_msg # (
	parameter CLK_RATE = 100000000,
	parameter BAUD_RATE = 115200
) (
	input clk,
	input rx,
	output [7:0] rx_msg_len,
	output [351:0] rx_msg_data,
	output rx_msg_ready
);

	reg [7:0] msg_l = 8'd0;
	reg [351:0] msg_d = 352'd0;
	reg msg_r = 1'b0;
	
	wire [7:0] rx_byte;
	wire rx_byte_new;
	
	reg [9:0] rx_byte_cnt = 10'd0;

	assign rx_msg_len = msg_l;
	assign rx_msg_data = msg_d;
	assign rx_msg_ready = msg_r;

	// Instantiate The Object For Serial Data Receive (Rx)
	uart_receiver # (.comm_clk_frequency(CLK_RATE), .baud_rate(BAUD_RATE)) uart_receiver (
		.clk(clk),
		.uart_rx(rx),
		.tx_byte(rx_byte),
		.tx_new_byte(rx_byte_new)
	);
	
	always @( posedge clk ) begin

		msg_r = 1'b0;
	
		if ( rx_byte_new ) begin
		
			if ( rx_byte_cnt == 10'd0 ) begin
			
				msg_l = 10'd0;
				msg_d = { 344'd0, rx_byte } ;
				
			end

			else begin
			
				msg_d = msg_d << 8;
				msg_d[7:0] = rx_byte;
				
			end
			
			rx_byte_cnt = rx_byte_cnt + 10'd1;

			if ( rx_byte_cnt == 10'd44 ) begin
			
				msg_r = 1'b1;
				msg_l = rx_byte_cnt[7:0];
				rx_byte_cnt = 10'd0;
				
			end
			
		end	

	end

endmodule


module write_msg # (
	parameter CLK_RATE = 100000000,
	parameter BAUD_RATE = 115200
) (
	input clk,
	output tx,
	input [31:0] msg_data,
	input msg_ready,
	output busy
);

	reg tx_byte_ready = 1'b0;
	reg [7:0] tx_byte = 8'd0;
	reg [31:0] msg = 32'd0;
	reg [4:0] mux_state = 5'b00000;
	
	wire tx_ready;

	// Instantiate The Object For Serial Data Transmit (Tx)
	uart_transmitter # (.comm_clk_frequency(CLK_RATE), .baud_rate(BAUD_RATE)) uart_transmitter (
		.clk(clk),
		.uart_tx(tx),
		.tx_ready(tx_ready),
		.rx_byte(tx_byte),
		.rx_new_byte(tx_byte_ready)
	);

	assign busy = (|mux_state);
	
	always @( posedge clk ) begin
	
		if ( msg_ready && !busy ) begin
		
			msg <= msg_data;
			mux_state <= 5'b11000;
			
		end
		else if ( mux_state[4] && ~mux_state[0] && tx_ready ) begin
		
			tx_byte <= msg[31:24];
			tx_byte_ready <= 1'b1;
			
			msg <= ( msg << 8 );
			mux_state <= mux_state + 5'd1;
		
		end
		else if ( mux_state[4] && mux_state[0] ) begin
		
			tx_byte_ready <= 1'b0;
			
			if (tx_ready)
				mux_state <= mux_state + 5'd1;

		end	

	end

endmodule
