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

module miner (
	input clk,
	input reset,
	input [351:0] block,
	output [31:0] golden_nonce,
	output golden_nonce_found
);

	wire hash_ready;
	wire [31:0] hash;
	wire [255:0] midstate;
	wire [95:0] data;
	
	assign { midstate, data } = block;

	reg [255:0] midstate_d, midstate_q;
	reg [95:0] data_d, data_q;
	reg [31:0] nonce_d, nonce_q;
	reg new_block_d, new_block_q;
	
	reg golden_nonce_found_d, golden_nonce_found_q;
	reg [31:0] golden_nonce_d, golden_nonce_q;

	assign golden_nonce = golden_nonce_q;
	assign golden_nonce_found = golden_nonce_found_q;
	
	blake256 blake256 ( clk, new_block_q, midstate_q, data_q, nonce_q, hash_ready, hash );

	initial begin
		
		midstate_q = 256'd0;
		data_q = 96'd0;
		nonce_q = 32'd0;
		new_block_q = 1'b0;
		
		golden_nonce_q = 32'hFFFFFFFF;
		golden_nonce_found_q = 1'b0;
		
	end

	always @(*) begin

		new_block_d = 1'b0;
		
		midstate_d = midstate_q;
		data_d = data_q;
		nonce_d = nonce_q + 32'd1;
		
		golden_nonce_d = 32'hFFFFFFFF;
		golden_nonce_found_d = 1'b0;

		// Reset The Block Data
		if ( reset ) begin
			
			midstate_d = midstate;
			data_d = data;
			nonce_d = 32'h00000000;
//			nonce_d = 32'hb90f721c;		// 32'hb90f721d
//			nonce_d = 32'hB90F7200;

			new_block_d = 1'b1;
			
		end

		// Check For Golden Nonce
//		if ( hash_ready && (hash == 32'h00) ) begin 
		if ( hash_ready && (hash[7:0] == 8'h00) ) begin 

			golden_nonce_found_d = 1'b1;
			golden_nonce_d = nonce_q - 32'd31;

		end

	end

	always @(posedge clk) begin

		new_block_q <= new_block_d;

		midstate_q <= midstate_d;
		data_q <= data_d;
		nonce_q <= nonce_d;

		golden_nonce_q <= golden_nonce_d;
		golden_nonce_found_q <= golden_nonce_found_d;

		$display("Nonce: %x, Ready: %d, Hash: %x", nonce_q-32'd31, hash_ready, hash);

	end

endmodule
