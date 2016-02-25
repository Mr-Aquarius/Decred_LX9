/*
 * Copyright (c) 2016 CryptoFlyr
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

module blake256 (
	input clk,
	input rst,
	input [255:0] state,
	input [95:0] data,
	input [31:0] nonce,
	output reg hash_ready,
	output reg [31:0] hash
);

	wire [511:0] v0,v1,t0;

	reg [511:0] m [0:13];

	reg [511:0] v;
	reg [31:0] nonce0=0,nonce1=0;
	reg [31:0] v1a,v1b;
	
	reg [3:0] rnd0,rnd1;
	
	reg read_nonce, calc_hash, select;

	assign v0 = (rnd0 == 4'd0) ? v : v1;

	blake_G g_0 (clk, v0[511:480], v0[383:352], v0[255:224], v0[127: 96], m[rnd0][511:480], m[rnd0][479:448], t0[511:480], t0[383:352], t0[255:224], t0[127: 96]);
	blake_G g_1 (clk, v0[479:448], v0[351:320], v0[223:192], v0[ 95: 64], m[rnd0][447:416], m[rnd0][415:384], t0[479:448], t0[351:320], t0[223:192], t0[ 95: 64]);
	blake_G g_2 (clk, v0[447:416], v0[319:288], v0[191:160], v0[ 63: 32], m[rnd0][383:352], m[rnd0][351:320], t0[447:416], t0[319:288], t0[191:160], t0[ 63: 32]);
	blake_G g_3 (clk, v0[415:384], v0[287:256], v0[159:128], v0[ 31:  0], m[rnd0][319:288], m[rnd0][287:256], t0[415:384], t0[287:256], t0[159:128], t0[ 31:  0]);

	blake_G g_4 (clk, t0[511:480], t0[351:320], t0[191:160], t0[ 31:  0], m[rnd1][255:224], m[rnd1][223:192], v1[511:480], v1[351:320], v1[191:160], v1[ 31:  0]);
	blake_G g_5 (clk, t0[479:448], t0[319:288], t0[159:128], t0[127: 96], m[rnd1][191:160], m[rnd1][159:128], v1[479:448], v1[319:288], v1[159:128], v1[127: 96]);
	blake_G g_6 (clk, t0[447:416], t0[287:256], t0[255:224], t0[ 95: 64], m[rnd1][127: 96], m[rnd1][ 95: 64], v1[447:416], v1[287:256], v1[255:224], v1[ 95: 64]);
	blake_G g_7 (clk, t0[415:384], t0[383:352], t0[223:192], t0[ 63: 32], m[rnd1][ 63: 32], m[rnd1][ 31:  0], v1[415:384], v1[383:352], v1[223:192], v1[ 63: 32]);


	always @ (posedge clk) begin

		if (rst) begin
			v <= { state, 256'h243F6A8885A308D313198A2E03707344A4093D82299F3470082EFA98EC4E6C89 };

			m[0] <= { data[95:64]^32'h85A308D3,data[63:32]^32'h243F6A88,data[31: 0]^32'h03707344,32'h00000000,32'h299F31D0,32'hA4093822,32'hEC4E6C89,32'h082EFA98,32'h38D01377,32'h452821E6,32'h34E90C6C,32'hBE5466CF,32'hC97C50DD,32'h40AC29B6,32'hB5470917,32'h3F84D015 };
			m[1] <= { 32'hBE5466CF,32'h3F84D5B5,32'h452821E6,32'hA4093822,32'hB5470917,32'h38D016D7,32'h882EFA99,32'hC97C50DD,data[63:32]^32'hC0AC29B7,32'h85A308D3,data[95:64]^32'h13198A2E,data[31: 0]^32'h243F6A88,32'hEC4E6C89,32'h34E90C6C,32'h03707344,32'h00000000 };
			m[2] <= { 32'h452821E6,32'h34E90C6C,32'h243F6A88,data[95:64]^32'hC0AC29B7,32'h13198A2E,data[31: 0]^32'h299F31D0,32'hC97C557D,32'h35470916,32'h3F84D5B5,32'hBE5466CF,32'h00000000,32'h03707344,32'h85A308D3,data[63:32]^32'hEC4E6C89,32'hA4093822,32'h38D01377 };
			m[3] <= { 32'h38D01377,32'hEC4E6C89,32'h00000000,data[63:32]^32'h03707344,32'h40AC29B6,32'hC97C50DD,32'h3F84D5B5,32'h34E90C6C,data[31: 0]^32'h082EFA98,32'h13198A2E,32'hBE5466CF,32'h299F31D0,32'h243F6A88,data[95:64]^32'hA4093822,32'h45282446,32'hB5470917 };
			m[4] <= { 32'h243F6A88,data[95:64]^32'h38D01377,32'hEC4E6C89,32'h299F31D0,data[31: 0]^32'hA4093822,32'h13198A2E,32'hB5470917,32'hBE54636F,32'h85A308D3,data[63:32]^32'h3F84D5B5,32'hC0AC29B7,32'h34E90C6C,32'h452821E6,32'h082EFA98,32'h00000000,32'h83707345 };
			m[5] <= { data[31: 0]^32'hC0AC29B7,32'h13198A2E,32'hBE5466CF,32'h082EFA98,data[95:64]^32'h34E90C6C,32'h243F6A88,32'h03707344,32'h00000000,32'hC97C50DD,32'h24093823,32'h299F31D0,32'hEC4E6C89,32'h3F84D015,32'hB5470917,data[63:32]^32'h38D01377,32'h85A308D3 };
			m[6] <= { 32'h299F31D0,32'hC0AC29B7,data[63:32]^32'hB5470917,32'h85A30D73,32'hC97C50DD,32'hBF84D5B4,32'hBE5466CF,32'hA4093822,data[95:64]^32'hEC4E6C89,32'h243F6A88,32'h03707344,32'h00000000,32'h13198A2E,data[31: 0]^32'h38D01377,32'h34E90C6C,32'h452821E6 };
			m[7] <= { 32'hB4E90C6D,32'hC97C50DD,32'h3F84D5B5,32'hEC4E6C89,32'h85A308D3,data[63:32]^32'hC0AC29B7,32'h00000000,32'h03707344,32'h243F6A88,data[95:64]^32'h299F31D0,32'hA4093D82,32'hB5470917,32'h082EFA98,32'h452821E6,data[31: 0]^32'hBE5466CF,32'h13198A2E };
			m[8] <= { 32'hB5470917,32'h082EFF38,32'h38D01377,32'h3F84D5B5,32'h03707344,32'h00000000,data[95:64]^32'h452821E6,32'h243F6A88,32'h13198A2E,data[31: 0]^32'hC0AC29B7,32'h6C4E6C88,32'hC97C50DD,data[63:32]^32'hA4093822,32'h85A308D3,32'h299F31D0,32'hBE5466CF };
			m[9] <= { 32'h13198A2E,data[31: 0]^32'hBE5466CF,32'hA4093822,32'h452821E6,32'h082EFA98,32'hEC4E6C89,data[63:32]^32'h299F31D0,32'h85A308D3,32'h34E909CC,32'hB5470917,32'h3F84D5B5,32'h38D01377,32'h00000000,32'h03707344,32'hA43F6A89,data[95:64]^32'hC97C50DD };
			m[10] <= { data[95:64]^32'h85A308D3,data[63:32]^32'h243F6A88,data[31: 0]^32'h03707344,32'h00000000,32'h299F31D0,32'hA4093822,32'hEC4E6C89,32'h082EFA98,32'h38D01377,32'h452821E6,32'h34E90C6C,32'hBE5466CF,32'hC97C50DD,32'h40AC29B6,32'hB5470917,32'h3F84D015 };
			m[11] <= { 32'hBE5466CF,32'h3F84D5B5,32'h452821E6,32'hA4093822,32'hB5470917,32'h38D016D7,32'h882EFA99,32'hC97C50DD,data[63:32]^32'hC0AC29B7,32'h85A308D3,data[95:64]^32'h13198A2E,data[31: 0]^32'h243F6A88,32'hEC4E6C89,32'h34E90C6C,32'h03707344,32'h00000000 };
			m[12] <= { 32'h452821E6,32'h34E90C6C,32'h243F6A88,data[95:64]^32'hC0AC29B7,32'h13198A2E,data[31: 0]^32'h299F31D0,32'hC97C557D,32'h35470916,32'h3F84D5B5,32'hBE5466CF,32'h00000000,32'h03707344,32'h85A308D3,data[63:32]^32'hEC4E6C89,32'hA4093822,32'h38D01377 };
			m[13] <= { 32'h38D01377,32'hEC4E6C89,32'h00000000,data[63:32]^32'h03707344,32'h40AC29B6,32'hC97C50DD,32'h3F84D5B5,32'h34E90C6C,data[31: 0]^32'h082EFA98,32'h13198A2E,32'hBE5466CF,32'h299F31D0,32'h243F6A88,data[95:64]^32'hA4093822,32'h45282446,32'hB5470917 };
			
			read_nonce <= 1'b1;
			
			rnd0 <= 4'd13;
			rnd1 <= 4'd12;
			select <= 1'b1;

		end
		else begin

			if (read_nonce) begin
				nonce0 <= nonce;
				m[0][415:384] <= nonce ^ 32'h13198A2E;
			end
			else begin
				nonce0 <= nonce1;
			end

			nonce1 <= nonce0;

//			m[0][415:384] <= nonce0 ^ 32'h13198A2E;  moved due to timing
			m[1][ 31:  0] <= nonce0 ^ 32'h299F31D0;
			m[2][191:160] <= nonce0 ^ 32'h082EFA98;
			m[3][447:416] <= nonce1 ^ 32'h85A308D3;
			m[4][ 63: 32] <= nonce0 ^ 32'hC97C50DD;
			m[5][287:256] <= nonce1 ^ 32'h452821E6;
			m[6][159:128] <= nonce0 ^ 32'h082EFA98;
			m[7][319:288] <= nonce1 ^ 32'h38D01377;
			m[8][351:320] <= nonce1 ^ 32'h34E90C6C;
			m[9][127: 96] <= nonce0 ^ 32'hC0AC29B7;
			m[10][415:384] <= nonce1 ^ 32'h13198A2E;
			m[11][ 31:  0] <= nonce0 ^ 32'h299F31D0;
			m[12][191:160] <= nonce0 ^ 32'h082EFA98;
			m[13][447:416] <= nonce1 ^ 32'h85A308D3;

			rnd1 <= rnd0;
			select <= ~select;

			// Calculate Hash
			if (calc_hash) begin
				hash <= v[287:256] ^ v1a ^ v1b;
				$display("Hash: %x", v[287:256] ^ v1a ^ v1b);
			end
			else
				hash <= 32'hFFFFFFFF;

			if (select) begin

				if (rnd0 == 4'd13) begin

					rnd0 <= 4'd0;
					read_nonce <= 1'b1;
					nonce0 <= nonce;
					m[0][415:384] <= nonce ^ 32'h13198A2E;

				end
				else begin

					rnd0 <= rnd0 + 4'd1;

				end
			end
			else begin
			
				read_nonce <= 1'b0;
				calc_hash <= 1'b0;
				
				if (rnd1 == 4'd13) begin
				
					calc_hash <= 1'b1;

				end
			
			end

		end

		v1a <= v1[287:256];
		v1b <= v1[31:0];
		
		hash_ready <= calc_hash;

	end

endmodule


module blake_G (
	input clk,
	input [31:0] a,
	input [31:0] b,
	input [31:0] c,
	input [31:0] d,
	input [31:0] m0,
	input [31:0] m1,
	output [31:0] a_out,
	output [31:0] b_out,
	output [31:0] c_out,
	output [31:0] d_out
);

	reg [31:0] A1,A2,B1,B2,C1,C2,D1,D2;
	reg [31:0] T1,T2,T3,T4;
	reg [31:0] A1x,B1x,C1x,D1x,m1x;
	
	assign a_out = A2;
	assign b_out = B2;
	assign c_out = C2;
	assign d_out = D2;

	always @ (posedge clk) begin

		A1 = a + b + m0;
		T1 = d ^ A1;
		D1 = { T1[15:0] , T1[31:16] };
		C1 = c + D1;
		T2 = b ^ C1;
		B1 = { T2[11:0] , T2[31:12] };

		A2 = A1 + B1 + m1;
		T3 = D1 ^ A2;
		D2 = { T3[7:0] , T3[31:8] };
		C2 = C1 + D2;
		T4 = B1 ^ C2;
		B2 = { T4[6:0] , T4[31:7] };

	end

endmodule
