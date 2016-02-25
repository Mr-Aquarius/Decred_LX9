/*
 * Copyright (c) 2016 Sprocket
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License with
 * additional permissions to the one published by the Free Software
 * Foundation, either version 3 of the License, or (at your option)
 * any later version. For more information see LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

module decred_lx9 (
	input  clk,								// 50 MHz Clock (Pin 85)
	input  rx,								// Host Serial Tx (Pin 83)
	output tx								// Host Serial Rx (Pin 82)
);
	
	wire new_block;
	wire [351:0] block;
	wire result_ready;
	wire [31:0] result;
	
	parameter CLK_RATE = 50000000;	// clk = 50 MHz
	parameter BAUD_RATE = 115200;		// baud = 115200 bps

	serial # (.CLK_RATE(CLK_RATE), .BAUD_RATE(BAUD_RATE)) uart (
		.clk(clk),
		.rx(rx),
		.tx(tx),
		.new_block(new_block),
		.block(block),
		.result_ready(result_ready),
		.result_in(result)
	);

	miner miner (
		.clk(clk),
		.reset(new_block),
		.block(block),
		.golden_nonce(result),
		.golden_nonce_found(result_ready)
	);
	
endmodule
