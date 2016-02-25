/*
*
* Copyright (c) 2011-2013 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

module uart_receiver # (
	parameter comm_clk_frequency = 100000000,
	parameter baud_rate = 115200
) (
	input clk,

	// UART interface
	input uart_rx,

	// Data received
	output reg tx_new_byte = 1'b0,
	output reg [7:0] tx_byte = 8'd0
);

	localparam [15:0] baud_delay = (comm_clk_frequency / baud_rate) - 1;

	//-----------------------------------------------------------------------------
	// UART Filtering
	//-----------------------------------------------------------------------------
	wire rx;

	uart_filter uart_fitler_blk (
		.clk (clk),
		.uart_rx (uart_rx),
		.tx_rx (rx)
	);


	//-----------------------------------------------------------------------------
	// UART Decoding
	//-----------------------------------------------------------------------------
	reg old_rx = 1'b1, idle = 1'b1;
	reg [15:0] delay_cnt = 16'd0;
	reg [8:0] incoming = 9'd0;

	always @ (posedge clk)
	begin
		old_rx <= rx;
		tx_new_byte <= 1'b0;

		delay_cnt <= delay_cnt + 16'd1;

		if (delay_cnt == baud_delay)
			delay_cnt <= 0;

		if (idle && old_rx && !rx)    // Start bit (falling edge)
		begin
			idle <= 1'b0;
			incoming <= 9'd511;
			delay_cnt <= 16'd0;   // Synchronize timer to falling edge
		end
		else if (!idle && (delay_cnt == (baud_delay >> 1)))
		begin
			incoming <= {rx, incoming[8:1]};    // LSB first

			if (incoming == 9'd511 && rx)       // False start bit
				idle <= 1'b1;
		
			if (!incoming[0])    // Expecting stop bit
			begin
				idle <= 1'b1;
				
				if (rx)
				begin
					tx_new_byte <= 1'b1;
					tx_byte <= incoming[8:1];
				end
			end
		end
	end

endmodule


/*
* Provides metastability protection, and some minimal noise filtering.
* Noise is filtered with a 3-way majority vote. This removes any random single
* 'clk' cycle errors.
*/
module uart_filter (
	input clk,
	input uart_rx,
	output reg tx_rx = 1'b0
);

	//-----------------------------------------------------------------------------
	// Metastability Protection
	//-----------------------------------------------------------------------------
	reg rx, meta;

	always @ (posedge clk)
		{rx, meta} <= {meta, uart_rx};


	//-----------------------------------------------------------------------------
	// Noise Filtering
	//-----------------------------------------------------------------------------
	wire sample0 = rx;
	reg sample1, sample2;

	always @ (posedge clk)
	begin
		{sample2, sample1} <= {sample1, sample0};

		if ((sample2 & sample1) | (sample1 & sample0) | (sample2 & sample0))
			tx_rx <= 1'b1;
		else
			tx_rx <= 1'b0;
	end

endmodule


/*
module serial_rx #(
	parameter CLK_PER_BIT = 50
)(
	input clk,
//	input rst,
	input rx,
	output [7:0] data,
	output new_data
);

	// clog2 is 'ceiling of log base 2' which gives you the number of bits needed to store a value
	parameter CTR_SIZE = $clog2(CLK_PER_BIT);

	localparam STATE_SIZE = 2;
	localparam IDLE = 2'd0,
				  WAIT_HALF = 2'd1,
				  WAIT_FULL = 2'd2,
				  WAIT_HIGH = 2'd3;

	reg [CTR_SIZE-1:0] ctr_d, ctr_q;
	reg [2:0] bit_ctr_d, bit_ctr_q;
	reg [7:0] data_d, data_q;
	reg new_data_d, new_data_q;
	reg [STATE_SIZE-1:0] state_d, state_q = IDLE;
	reg rx_d, rx_q;

	assign new_data = new_data_q;
	assign data = data_q;

	always @(*) begin
		rx_d = rx;
		state_d = state_q;
		ctr_d = ctr_q;
		bit_ctr_d = bit_ctr_q;
		data_d = data_q;
		new_data_d = 1'b0;

		case (state_q)
			IDLE: begin
				bit_ctr_d = 3'b0;
				ctr_d = 1'b0;
				if (rx_q == 1'b0) begin
					state_d = WAIT_HALF;
				end
			end
			WAIT_HALF: begin
				ctr_d = ctr_q + 1'b1;
				if (ctr_q == (CLK_PER_BIT >> 1)) begin
					ctr_d = 1'b0;
					state_d = WAIT_FULL;
				end
			end
			WAIT_FULL: begin
				ctr_d = ctr_q + 1'b1;
				if (ctr_q == CLK_PER_BIT - 1) begin
					data_d = {rx_q, data_q[7:1]};
					bit_ctr_d = bit_ctr_q + 1'b1;
					ctr_d = 1'b0;
					if (bit_ctr_q == 3'd7) begin
						state_d = WAIT_HIGH;
						new_data_d = 1'b1;
					end
				end
			end
			WAIT_HIGH: begin
				if (rx_q == 1'b1) begin
					state_d = IDLE;
				end
			end
			default: begin
				state_d = IDLE;
			end
		endcase
	end

    always @(posedge clk) begin
//		if (rst) begin
//			ctr_q <= 1'b0;
//			bit_ctr_q <= 3'b0;
//			new_data_q <= 1'b0;
//			state_q <= IDLE;
//		end else begin
			ctr_q <= ctr_d;
			bit_ctr_q <= bit_ctr_d;
			new_data_q <= new_data_d;
			state_q <= state_d;
//		end

        rx_q <= rx_d;
        data_q <= data_d;
    end

endmodule
*/
