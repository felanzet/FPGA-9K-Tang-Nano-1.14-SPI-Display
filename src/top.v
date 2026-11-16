// HELLO / TANG NANO 9K - Layout ottimizzato
`timescale 1ps/1ps

module lcd114_test(
	input clk, // 27M
	input resetn,
	output ser_tx,
	input ser_rx,
	output lcd_resetn,
	output lcd_clk,
	output lcd_cs,
	output lcd_rs,
	output lcd_data
);

localparam MAX_CMDS = 69;
wire [8:0] init_cmd[MAX_CMDS:0];

assign init_cmd[ 0] = 9'h036; assign init_cmd[ 1] = 9'h170;
assign init_cmd[ 2] = 9'h03A; assign init_cmd[ 3] = 9'h105;
assign init_cmd[ 4] = 9'h0B2; assign init_cmd[ 5] = 9'h10C;
assign init_cmd[ 6] = 9'h10C; assign init_cmd[ 7] = 9'h100;
assign init_cmd[ 8] = 9'h133; assign init_cmd[ 9] = 9'h133;
assign init_cmd[10] = 9'h0B7; assign init_cmd[11] = 9'h135;
assign init_cmd[12] = 9'h0BB; assign init_cmd[13] = 9'h119;
assign init_cmd[14] = 9'h0C0; assign init_cmd[15] = 9'h12C;
assign init_cmd[16] = 9'h0C2; assign init_cmd[17] = 9'h101;
assign init_cmd[18] = 9'h0C3; assign init_cmd[19] = 9'h112;
assign init_cmd[20] = 9'h0C4; assign init_cmd[21] = 9'h120;
assign init_cmd[22] = 9'h0C6; assign init_cmd[23] = 9'h10F;
assign init_cmd[24] = 9'h0D0; assign init_cmd[25] = 9'h1A4;
assign init_cmd[26] = 9'h1A1; assign init_cmd[27] = 9'h0E0;
assign init_cmd[28] = 9'h1D0; assign init_cmd[29] = 9'h104;
assign init_cmd[30] = 9'h10D; assign init_cmd[31] = 9'h111;
assign init_cmd[32] = 9'h113; assign init_cmd[33] = 9'h12B;
assign init_cmd[34] = 9'h13F; assign init_cmd[35] = 9'h154;
assign init_cmd[36] = 9'h14C; assign init_cmd[37] = 9'h118;
assign init_cmd[38] = 9'h10D; assign init_cmd[39] = 9'h10B;
assign init_cmd[40] = 9'h11F; assign init_cmd[41] = 9'h123;
assign init_cmd[42] = 9'h0E1; assign init_cmd[43] = 9'h1D0;
assign init_cmd[44] = 9'h104; assign init_cmd[45] = 9'h10C;
assign init_cmd[46] = 9'h111; assign init_cmd[47] = 9'h113;
assign init_cmd[48] = 9'h12C; assign init_cmd[49] = 9'h13F;
assign init_cmd[50] = 9'h144; assign init_cmd[51] = 9'h151;
assign init_cmd[52] = 9'h12F; assign init_cmd[53] = 9'h11F;
assign init_cmd[54] = 9'h11F; assign init_cmd[55] = 9'h120;
assign init_cmd[56] = 9'h123; assign init_cmd[57] = 9'h021;
assign init_cmd[58] = 9'h029;
assign init_cmd[59] = 9'h02A; assign init_cmd[60] = 9'h100;
assign init_cmd[61] = 9'h128; assign init_cmd[62] = 9'h101;
assign init_cmd[63] = 9'h117; assign init_cmd[64] = 9'h02B;
assign init_cmd[65] = 9'h100; assign init_cmd[66] = 9'h135;
assign init_cmd[67] = 9'h100; assign init_cmd[68] = 9'h1BB;
assign init_cmd[69] = 9'h02C;

localparam INIT_RESET = 4'b0000; localparam INIT_PREPARE = 4'b0001;
localparam INIT_WAKEUP = 4'b0010; localparam INIT_SNOOZE = 4'b0011;
localparam INIT_WORKING = 4'b0100; localparam INIT_DONE = 4'b0101;

`ifdef MODELTECH
localparam CNT_100MS = 32'd2700000; localparam CNT_120MS = 32'd3240000; localparam CNT_200MS = 32'd5400000;
`else
localparam CNT_100MS = 32'd27; localparam CNT_120MS = 32'd32; localparam CNT_200MS = 32'd54;
`endif

reg [3:0] init_state; reg [6:0] cmd_index;
reg [31:0] clk_cnt; reg [4:0] bit_loop;
reg [15:0] pixel_cnt;
reg lcd_cs_r; reg lcd_rs_r; reg lcd_reset_r;
reg [7:0] spi_data;

reg [7:0] cur_x;
reg [7:0] cur_y;

assign lcd_resetn = lcd_reset_r;
assign lcd_clk = ~clk;
assign lcd_cs = lcd_cs_r;
assign lcd_rs = lcd_rs_r;
assign lcd_data = spi_data[7]; 

wire [15:0] pixel; 

// =========================================================
// GENERATORE DI CARATTERI (8x8)
// =========================================================

function [7:0] get_char;
    input [4:0] char;
    input [2:0] row;
    begin
        case(char)
            5'd1: case(row) 0:get_char=8'b11000011; 1:get_char=8'b11000011; 2:get_char=8'b11000011; 3:get_char=8'b11111111; 4:get_char=8'b11000011; 5:get_char=8'b11000011; 6:get_char=8'b11000011; 7:get_char=8'b11000011; endcase // H
            5'd2: case(row) 0:get_char=8'b11111111; 1:get_char=8'b11000000; 2:get_char=8'b11000000; 3:get_char=8'b11111100; 4:get_char=8'b11000000; 5:get_char=8'b11000000; 6:get_char=8'b11000000; 7:get_char=8'b11111111; endcase // E
            5'd3: case(row) 0:get_char=8'b11000000; 1:get_char=8'b11000000; 2:get_char=8'b11000000; 3:get_char=8'b11000000; 4:get_char=8'b11000000; 5:get_char=8'b11000000; 6:get_char=8'b11000000; 7:get_char=8'b11111111; endcase // L
            5'd4: case(row) 0:get_char=8'b00111100; 1:get_char=8'b11000011; 2:get_char=8'b11000011; 3:get_char=8'b11000011; 4:get_char=8'b11000011; 5:get_char=8'b11000011; 6:get_char=8'b11000011; 7:get_char=8'b00111100; endcase // O
            5'd5: case(row) 0:get_char=8'b11000011; 1:get_char=8'b11000011; 2:get_char=8'b11000011; 3:get_char=8'b11011011; 4:get_char=8'b11111111; 5:get_char=8'b11100111; 6:get_char=8'b11000011; 7:get_char=8'b11000011; endcase // W (non usata)
            5'd6: case(row) 0:get_char=8'b11111100; 1:get_char=8'b11000110; 2:get_char=8'b11000110; 3:get_char=8'b11111100; 4:get_char=8'b11011000; 5:get_char=8'b11001100; 6:get_char=8'b11000110; 7:get_char=8'b11000011; endcase // R (non usata)
            5'd7: case(row) 0:get_char=8'b11111100; 1:get_char=8'b11000110; 2:get_char=8'b11000011; 3:get_char=8'b11000011; 4:get_char=8'b11000011; 5:get_char=8'b11000011; 6:get_char=8'b11000110; 7:get_char=8'b11111100; endcase // D (non usata)
            5'd8: case(row) 0:get_char=8'b00111111; 1:get_char=8'b01100000; 2:get_char=8'b11000000; 3:get_char=8'b11000000; 4:get_char=8'b11000000; 5:get_char=8'b11000000; 6:get_char=8'b01100000; 7:get_char=8'b00111111; endcase // C
            5'd9: case(row) 0:get_char=8'b11111111; 1:get_char=8'b00011000; 2:get_char=8'b00011000; 3:get_char=8'b00011000; 4:get_char=8'b00011000; 5:get_char=8'b00011000; 6:get_char=8'b00011000; 7:get_char=8'b11111111; endcase // I
            5'd10: case(row) 0:get_char=8'b00111100; 1:get_char=8'b01100110; 2:get_char=8'b11000011; 3:get_char=8'b11000011; 4:get_char=8'b11111111; 5:get_char=8'b11000011; 6:get_char=8'b11000011; 7:get_char=8'b11000011; endcase // A
            5'd11: case(row) 0:get_char=8'b11111111; 1:get_char=8'b00011000; 2:get_char=8'b00011000; 3:get_char=8'b00011000; 4:get_char=8'b00011000; 5:get_char=8'b00011000; 6:get_char=8'b00011000; 7:get_char=8'b00011000; endcase // T
            5'd12: case(row) 0:get_char=8'b11000011; 1:get_char=8'b11100011; 2:get_char=8'b11110011; 3:get_char=8'b11011011; 4:get_char=8'b11001111; 5:get_char=8'b11000111; 6:get_char=8'b11000011; 7:get_char=8'b11000011; endcase // N
            5'd13: case(row) 0:get_char=8'b00111100; 1:get_char=8'b01100010; 2:get_char=8'b11000000; 3:get_char=8'b11000000; 4:get_char=8'b11001111; 5:get_char=8'b11000011; 6:get_char=8'b01100010; 7:get_char=8'b00111100; endcase // G
            5'd14: case(row) 0:get_char=8'b00111100; 1:get_char=8'b11000011; 2:get_char=8'b11000011; 3:get_char=8'b01111111; 4:get_char=8'b00000011; 5:get_char=8'b00000011; 6:get_char=8'b11000011; 7:get_char=8'b00111100; endcase // 9
            5'd15: case(row) 0:get_char=8'b11000011; 1:get_char=8'b11000110; 2:get_char=8'b11001100; 3:get_char=8'b11111000; 4:get_char=8'b11001100; 5:get_char=8'b11000110; 6:get_char=8'b11000011; 7:get_char=8'b11000011; endcase // K
            default: get_char = 8'b00000000; // Spazio
        endcase
    end
endfunction

// Testi
// "HELLO" - 5 caratteri
wire [4:0] msg1 [0:4];
assign msg1[0]=1; assign msg1[1]=2; assign msg1[2]=3; assign msg1[3]=3; assign msg1[4]=4;

// "TANG NANO 9K" - 12 caratteri
wire [4:0] msg2 [0:11];
assign msg2[0]=11; assign msg2[1]=10; assign msg2[2]=12; assign msg2[3]=13; assign msg2[4]=0; 
assign msg2[5]=12; assign msg2[6]=10; assign msg2[7]=12; assign msg2[8]=4; assign msg2[9]=0; 
assign msg2[10]=14; assign msg2[11]=15; 

// Posizionamento (BLOCK_SIZE=3 riduce le dimensioni e lascia spazio)
localparam BS = 3; 
localparam CHAR_W = 8 * BS; 

// Calcoli per il centraggio dinamico
// Riga 1: 5 caratteri -> Larghezza = 5 * 24 = 120. Centro = (240 - 120) / 2 = 60
localparam OFFSET_X1 = 60; localparam OFFSET_Y1 = 30;

// Riga 2: 12 caratteri -> Larghezza = 12 * 24 = 288. 
// E' troppo larga! Dobbiamo ridurre la scala per la riga 2 o spaziare meglio.
// Usiamo SCALE=2 per la seconda riga per farla stare tutta.
localparam BS2 = 2;
localparam CHAR_W2 = 8 * BS2;

// Riga 2: 12 caratteri -> Larghezza = 12 * 16 = 192. Centro = (240 - 192) / 2 = 24
localparam OFFSET_X2 = 24; localparam OFFSET_Y2 = 80;

// Calcolo Riga 1
wire [7:0] rel_x1 = (cur_x >= OFFSET_X1) ? (cur_x - OFFSET_X1) : 0;
wire [7:0] rel_y1 = (cur_y >= OFFSET_Y1) ? (cur_y - OFFSET_Y1) : 0;
wire [4:0] idx1 = rel_x1 / CHAR_W;
wire [2:0] col1 = (rel_x1 % CHAR_W) / BS;
wire [2:0] row1 = rel_y1 / BS;
wire in1 = (cur_x >= OFFSET_X1) && (cur_x < OFFSET_X1 + 5*CHAR_W) && (cur_y >= OFFSET_Y1) && (cur_y < OFFSET_Y1 + 8*BS);
wire px1 = in1 && ((get_char(msg1[idx1], row1) >> (7 - col1)) & 1);

// Calcolo Riga 2
wire [7:0] rel_x2 = (cur_x >= OFFSET_X2) ? (cur_x - OFFSET_X2) : 0;
wire [7:0] rel_y2 = (cur_y >= OFFSET_Y2) ? (cur_y - OFFSET_Y2) : 0;
wire [4:0] idx2 = rel_x2 / CHAR_W2;
wire [2:0] col2 = (rel_x2 % CHAR_W2) / BS2;
wire [2:0] row2 = rel_y2 / BS2;
wire in2 = (cur_x >= OFFSET_X2) && (cur_x < OFFSET_X2 + 12*CHAR_W2) && (cur_y >= OFFSET_Y2) && (cur_y < OFFSET_Y2 + 8*BS2);
wire px2 = in2 && ((get_char(msg2[idx2], row2) >> (7 - col2)) & 1);

// Colore finale: Giallo per HELLO, Azzurro/Ciano per TANG NANO 9K
assign pixel = px1 ? 16'hFFE0 : (px2 ? 16'h07FF : 16'h0000); 

// =========================================================

always@(posedge clk or negedge resetn) begin
	if (~resetn) begin
		clk_cnt <= 0; cmd_index <= 0; init_state <= INIT_RESET;
		lcd_cs_r <= 1; lcd_rs_r <= 1; lcd_reset_r <= 0;
		spi_data <= 8'hFF; bit_loop <= 0; pixel_cnt <= 0;
		cur_x <= 0; cur_y <= 0;
	end else begin
		case (init_state)
			INIT_RESET : begin
				if (clk_cnt == CNT_100MS) begin clk_cnt <= 0; init_state <= INIT_PREPARE; lcd_reset_r <= 1; end 
				else clk_cnt <= clk_cnt + 1;
			end
			INIT_PREPARE : begin
				if (clk_cnt == CNT_200MS) begin clk_cnt <= 0; init_state <= INIT_WAKEUP; end 
				else clk_cnt <= clk_cnt + 1;
			end
			INIT_WAKEUP : begin
				if (bit_loop == 0) begin lcd_cs_r <= 0; lcd_rs_r <= 0; spi_data <= 8'h11; bit_loop <= bit_loop + 1; end 
				else if (bit_loop == 8) begin lcd_cs_r <= 1; lcd_rs_r <= 1; bit_loop <= 0; init_state <= INIT_SNOOZE; end 
				else begin spi_data <= { spi_data[6:0], 1'b1 }; bit_loop <= bit_loop + 1; end
			end
			INIT_SNOOZE : begin
				if (clk_cnt == CNT_120MS) begin clk_cnt <= 0; init_state <= INIT_WORKING; end 
				else clk_cnt <= clk_cnt + 1;
			end
			INIT_WORKING : begin
				if (cmd_index == MAX_CMDS + 1) begin init_state <= INIT_DONE; end 
				else begin
					if (bit_loop == 0) begin lcd_cs_r <= 0; lcd_rs_r <= init_cmd[cmd_index][8]; spi_data <= init_cmd[cmd_index][7:0]; bit_loop <= bit_loop + 1; end 
					else if (bit_loop == 8) begin lcd_cs_r <= 1; lcd_rs_r <= 1; bit_loop <= 0; cmd_index <= cmd_index + 1; end 
					else begin spi_data <= { spi_data[6:0], 1'b1 }; bit_loop <= bit_loop + 1; end
				end
			end
			INIT_DONE : begin
				if (pixel_cnt == 32400) begin ; end 
				else begin
					if (bit_loop == 0) begin lcd_cs_r <= 0; lcd_rs_r <= 1; spi_data <= pixel[15:8]; bit_loop <= bit_loop + 1; end 
					else if (bit_loop == 8) begin spi_data <= pixel[7:0]; bit_loop <= bit_loop + 1; end 
					else if (bit_loop == 16) begin 
						lcd_cs_r <= 1; lcd_rs_r <= 1; bit_loop <= 0; pixel_cnt <= pixel_cnt + 1; 
						
						if (cur_x == 239) begin
							cur_x <= 0;
							if (cur_y == 134) cur_y <= 0;
							else cur_y <= cur_y + 1;
						end else begin
							cur_x <= cur_x + 1;
						end
					end 
					else begin spi_data <= { spi_data[6:0], 1'b1 }; bit_loop <= bit_loop + 1; end
				end
			end
		endcase
	end
end
endmodule