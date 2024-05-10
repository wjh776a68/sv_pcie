`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: 09/13/2023 02:45:50 PM
// Design Name: 
// Module Name: ram_ctrl
// Project Name: 
// Target Devices: XCVU37P
// Tool Versions:  Vivado 2023.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ram_ctrl #(
    parameter RAM_DEPTH = 1024,
    parameter BYTEADDR_WIDTH = $clog2(RAM_DEPTH * 32 / 8),
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH / 4)
) (
    input  wire clk,

    output reg [127:0]                 ram_douta,
    output reg [127:0]                 ram_doutb,
    input  wire [BYTEADDR_WIDTH - 1:0] ram_byteaddra,
    input  wire [BYTEADDR_WIDTH - 1:0] ram_byteaddrb,
    input  wire [127:0]                ram_dina,
    input  wire [127:0]                ram_dinb,
    input  wire [15:0]                 ram_wea,
    input  wire [15:0]                 ram_web,
    input  wire                        ram_ena,
    input  wire                        ram_enb
);

    wire [127:0]            ram_lo_douta, ram_hi_douta;
    wire [127:0]            ram_lo_doutb, ram_hi_doutb;
    reg  [ADDR_WIDTH - 1:0] ram_lo_addra, ram_hi_addra;
    reg  [ADDR_WIDTH - 1:0] ram_lo_addrb, ram_hi_addrb;
    reg  [127:0]            ram_lo_dina, ram_hi_dina;
    reg  [127:0]            ram_lo_dinb, ram_hi_dinb;
    reg  [15:0]             ram_lo_wea, ram_hi_wea;
    reg  [15:0]             ram_lo_web, ram_hi_web;

    reg [BYTEADDR_WIDTH - 1:0] ram_byteaddra_r, ram_byteaddra_rr;
    reg [BYTEADDR_WIDTH - 1:0] ram_byteaddrb_r, ram_byteaddrb_rr;

    always @(posedge clk) begin
        if (ram_ena) begin
            ram_byteaddra_r <= ram_byteaddra;
            ram_byteaddra_rr <= ram_byteaddra_r;
        end
    end

    always @(posedge clk) begin
        case (ram_byteaddra_rr[4 : 0]) 
        5'b00000: begin
            ram_douta <= ram_lo_douta; 
        end
        5'b10000: begin
            ram_douta <= ram_hi_douta; 
        end
        5'b00001: begin
            ram_douta <= {ram_hi_douta[0 +: 1 * 8], ram_lo_douta[1 * 8 +: 15 * 8]}; 
        end
        5'b00010: begin
            ram_douta <= {ram_hi_douta[0 +: 2 * 8], ram_lo_douta[2 * 8 +: 14 * 8]}; 
        end
        5'b00011: begin
            ram_douta <= {ram_hi_douta[0 +: 3 * 8], ram_lo_douta[3 * 8 +: 13 * 8]}; 
        end
        5'b00100: begin
            ram_douta <= {ram_hi_douta[0 +: 4 * 8], ram_lo_douta[4 * 8 +: 12 * 8]}; 
        end
        5'b00101: begin
            ram_douta <= {ram_hi_douta[0 +: 5 * 8], ram_lo_douta[5 * 8 +: 11 * 8]}; 
        end
        5'b00110: begin
            ram_douta <= {ram_hi_douta[0 +: 6 * 8], ram_lo_douta[6 * 8 +: 10 * 8]}; 
        end
        5'b00111: begin
            ram_douta <= {ram_hi_douta[0 +: 7 * 8], ram_lo_douta[7 * 8 +: 9 * 8]}; 
        end
        5'b01000: begin
            ram_douta <= {ram_hi_douta[0 +: 8 * 8], ram_lo_douta[8 * 8 +: 8 * 8]}; 
        end
        5'b01001: begin
            ram_douta <= {ram_hi_douta[0 +: 9 * 8], ram_lo_douta[9 * 8 +: 7 * 8]}; 
        end
        5'b01010: begin
            ram_douta <= {ram_hi_douta[0 +: 10 * 8], ram_lo_douta[10 * 8 +: 6 * 8]}; 
        end
        5'b01011: begin
            ram_douta <= {ram_hi_douta[0 +: 11 * 8], ram_lo_douta[11 * 8 +: 5 * 8]}; 
        end
        5'b01100: begin
            ram_douta <= {ram_hi_douta[0 +: 12 * 8], ram_lo_douta[12 * 8 +: 4 * 8]}; 
        end
        5'b01101: begin
            ram_douta <= {ram_hi_douta[0 +: 13 * 8], ram_lo_douta[13 * 8 +: 3 * 8]}; 
        end
        5'b01110: begin
            ram_douta <= {ram_hi_douta[0 +: 14 * 8], ram_lo_douta[14 * 8 +: 2 * 8]}; 
        end
        5'b01111: begin
            ram_douta <= {ram_hi_douta[0 +: 15 * 8], ram_lo_douta[15 * 8 +: 1 * 8]}; 
        end
        5'b10001: begin
            ram_douta <= {ram_lo_douta[0 +: 1 * 8], ram_hi_douta[1 * 8 +: 15 * 8]}; 
        end
        5'b10010: begin
            ram_douta <= {ram_lo_douta[0 +: 2 * 8], ram_hi_douta[2 * 8 +: 14 * 8]}; 
        end
        5'b10011: begin
            ram_douta <= {ram_lo_douta[0 +: 3 * 8], ram_hi_douta[3 * 8 +: 13 * 8]}; 
        end
        5'b10100: begin
            ram_douta <= {ram_lo_douta[0 +: 4 * 8], ram_hi_douta[4 * 8 +: 12 * 8]}; 
        end
        5'b10101: begin
            ram_douta <= {ram_lo_douta[0 +: 5 * 8], ram_hi_douta[5 * 8 +: 11 * 8]}; 
        end
        5'b10110: begin
            ram_douta <= {ram_lo_douta[0 +: 6 * 8], ram_hi_douta[6 * 8 +: 10 * 8]}; 
        end
        5'b10111: begin
            ram_douta <= {ram_lo_douta[0 +: 7 * 8], ram_hi_douta[7 * 8 +: 9 * 8]}; 
        end
        5'b11000: begin
            ram_douta <= {ram_lo_douta[0 +: 8 * 8], ram_hi_douta[8 * 8 +: 8 * 8]}; 
        end
        5'b11001: begin
            ram_douta <= {ram_lo_douta[0 +: 9 * 8], ram_hi_douta[9 * 8 +: 7 * 8]}; 
        end
        5'b11010: begin
            ram_douta <= {ram_lo_douta[0 +: 10 * 8], ram_hi_douta[10 * 8 +: 6 * 8]}; 
        end
        5'b11011: begin
            ram_douta <= {ram_lo_douta[0 +: 11 * 8], ram_hi_douta[11 * 8 +: 5 * 8]}; 
        end
        5'b11100: begin
            ram_douta <= {ram_lo_douta[0 +: 12 * 8], ram_hi_douta[12 * 8 +: 4 * 8]}; 
        end
        5'b11101: begin
            ram_douta <= {ram_lo_douta[0 +: 13 * 8], ram_hi_douta[13 * 8 +: 3 * 8]}; 
        end
        5'b11110: begin
            ram_douta <= {ram_lo_douta[0 +: 14 * 8], ram_hi_douta[14 * 8 +: 2 * 8]}; 
        end
        5'b11111: begin
            ram_douta <= {ram_lo_douta[0 +: 15 * 8], ram_hi_douta[15 * 8 +: 1 * 8]}; 
        end
        endcase
    end

    always @(posedge clk) begin
        if (ram_enb) begin
            ram_byteaddrb_r  <= ram_byteaddrb;
            ram_byteaddrb_rr <= ram_byteaddrb_r;
        end
    end

    always @(posedge clk) begin
        case (ram_byteaddrb_rr[4 : 0]) 
        5'b00000: begin
            ram_doutb <= ram_lo_doutb; 
        end
        5'b10000: begin
            ram_doutb <= ram_hi_doutb; 
        end
        5'b00001: begin
            ram_doutb <= {ram_hi_doutb[0 +: 1 * 8], ram_lo_doutb[1 * 8 +: 15 * 8]}; 
        end
        5'b00010: begin
            ram_doutb <= {ram_hi_doutb[0 +: 2 * 8], ram_lo_doutb[2 * 8 +: 14 * 8]}; 
        end
        5'b00011: begin
            ram_doutb <= {ram_hi_doutb[0 +: 3 * 8], ram_lo_doutb[3 * 8 +: 13 * 8]}; 
        end
        5'b00100: begin
            ram_doutb <= {ram_hi_doutb[0 +: 4 * 8], ram_lo_doutb[4 * 8 +: 12 * 8]}; 
        end
        5'b00101: begin
            ram_doutb <= {ram_hi_doutb[0 +: 5 * 8], ram_lo_doutb[5 * 8 +: 11 * 8]}; 
        end
        5'b00110: begin
            ram_doutb <= {ram_hi_doutb[0 +: 6 * 8], ram_lo_doutb[6 * 8 +: 10 * 8]}; 
        end
        5'b00111: begin
            ram_doutb <= {ram_hi_doutb[0 +: 7 * 8], ram_lo_doutb[7 * 8 +: 9 * 8]}; 
        end
        5'b01000: begin
            ram_doutb <= {ram_hi_doutb[0 +: 8 * 8], ram_lo_doutb[8 * 8 +: 8 * 8]}; 
        end
        5'b01001: begin
            ram_doutb <= {ram_hi_doutb[0 +: 9 * 8], ram_lo_doutb[9 * 8 +: 7 * 8]}; 
        end
        5'b01010: begin
            ram_doutb <= {ram_hi_doutb[0 +: 10 * 8], ram_lo_doutb[10 * 8 +: 6 * 8]}; 
        end
        5'b01011: begin
            ram_doutb <= {ram_hi_doutb[0 +: 11 * 8], ram_lo_doutb[11 * 8 +: 5 * 8]}; 
        end
        5'b01100: begin
            ram_doutb <= {ram_hi_doutb[0 +: 12 * 8], ram_lo_doutb[12 * 8 +: 4 * 8]}; 
        end
        5'b01101: begin
            ram_doutb <= {ram_hi_doutb[0 +: 13 * 8], ram_lo_doutb[13 * 8 +: 3 * 8]}; 
        end
        5'b01110: begin
            ram_doutb <= {ram_hi_doutb[0 +: 14 * 8], ram_lo_doutb[14 * 8 +: 2 * 8]}; 
        end
        5'b01111: begin
            ram_doutb <= {ram_hi_doutb[0 +: 15 * 8], ram_lo_doutb[15 * 8 +: 1 * 8]}; 
        end
        5'b10001: begin
            ram_doutb <= {ram_lo_doutb[0 +: 1 * 8], ram_hi_doutb[1 * 8 +: 15 * 8]}; 
        end
        5'b10010: begin
            ram_doutb <= {ram_lo_doutb[0 +: 2 * 8], ram_hi_doutb[2 * 8 +: 14 * 8]}; 
        end
        5'b10011: begin
            ram_doutb <= {ram_lo_doutb[0 +: 3 * 8], ram_hi_doutb[3 * 8 +: 13 * 8]}; 
        end
        5'b10100: begin
            ram_doutb <= {ram_lo_doutb[0 +: 4 * 8], ram_hi_doutb[4 * 8 +: 12 * 8]}; 
        end
        5'b10101: begin
            ram_doutb <= {ram_lo_doutb[0 +: 5 * 8], ram_hi_doutb[5 * 8 +: 11 * 8]}; 
        end
        5'b10110: begin
            ram_doutb <= {ram_lo_doutb[0 +: 6 * 8], ram_hi_doutb[6 * 8 +: 10 * 8]}; 
        end
        5'b10111: begin
            ram_doutb <= {ram_lo_doutb[0 +: 7 * 8], ram_hi_doutb[7 * 8 +: 9 * 8]}; 
        end
        5'b11000: begin
            ram_doutb <= {ram_lo_doutb[0 +: 8 * 8], ram_hi_doutb[8 * 8 +: 8 * 8]}; 
        end
        5'b11001: begin
            ram_doutb <= {ram_lo_doutb[0 +: 9 * 8], ram_hi_doutb[9 * 8 +: 7 * 8]}; 
        end
        5'b11010: begin
            ram_doutb <= {ram_lo_doutb[0 +: 10 * 8], ram_hi_doutb[10 * 8 +: 6 * 8]}; 
        end
        5'b11011: begin
            ram_doutb <= {ram_lo_doutb[0 +: 11 * 8], ram_hi_doutb[11 * 8 +: 5 * 8]}; 
        end
        5'b11100: begin
            ram_doutb <= {ram_lo_doutb[0 +: 12 * 8], ram_hi_doutb[12 * 8 +: 4 * 8]}; 
        end
        5'b11101: begin
            ram_doutb <= {ram_lo_doutb[0 +: 13 * 8], ram_hi_doutb[13 * 8 +: 3 * 8]}; 
        end
        5'b11110: begin
            ram_doutb <= {ram_lo_doutb[0 +: 14 * 8], ram_hi_doutb[14 * 8 +: 2 * 8]}; 
        end
        5'b11111: begin
            ram_doutb <= {ram_lo_doutb[0 +: 15 * 8], ram_hi_doutb[15 * 8 +: 1 * 8]}; 
        end
        endcase
    end

    always @(*) begin
        case (ram_byteaddra[4])
        1'b0: begin
            ram_lo_addra <= ram_byteaddra[BYTEADDR_WIDTH - 1 : 5];
            ram_hi_addra <= ram_byteaddra[BYTEADDR_WIDTH - 1 : 5];
        end
        1'b1: begin
            ram_lo_addra <= ram_byteaddra[BYTEADDR_WIDTH - 1 : 5] + 1;
            ram_hi_addra <= ram_byteaddra[BYTEADDR_WIDTH - 1 : 5];
        end
        endcase 

        case (ram_byteaddra[4 : 0]) 
        5'b00000: begin
            ram_lo_wea <= ram_wea;
            ram_hi_wea <= 0;
            ram_lo_dina <= ram_dina;
            ram_hi_dina <= 0;
        end
        5'b10000: begin
            ram_lo_wea <= 0;
            ram_hi_wea <= ram_wea;
            ram_lo_dina <= 0;
            ram_hi_dina <= ram_dina;
        end
        5'b00001: begin
            ram_lo_wea <= {ram_wea[0 +: 15], 1'b0};
            ram_hi_wea <= {15'b0, ram_wea[15 +: 1]};
            ram_lo_dina <= {ram_dina[0 +: 15 * 8], {1{8'bx}}};
            ram_hi_dina <= {{15{8'bx}}, ram_dina[15 * 8 +: 1 * 8]};
        end
        5'b00010: begin
            ram_lo_wea <= {ram_wea[0 +: 14], 2'b0};
            ram_hi_wea <= {14'b0, ram_wea[14 +: 2]};
            ram_lo_dina <= {ram_dina[0 +: 14 * 8], {2{8'bx}}};
            ram_hi_dina <= {{14{8'bx}}, ram_dina[14 * 8 +: 2 * 8]};
        end
        5'b00011: begin
            ram_lo_wea <= {ram_wea[0 +: 13], 3'b0};
            ram_hi_wea <= {13'b0, ram_wea[13 +: 3]};
            ram_lo_dina <= {ram_dina[0 +: 13 * 8], {3{8'bx}}};
            ram_hi_dina <= {{13{8'bx}}, ram_dina[13 * 8 +: 3 * 8]};
        end
        5'b00100: begin
            ram_lo_wea <= {ram_wea[0 +: 12], 4'b0};
            ram_hi_wea <= {12'b0, ram_wea[12 +: 4]};
            ram_lo_dina <= {ram_dina[0 +: 12 * 8], {4{8'bx}}};
            ram_hi_dina <= {{12{8'bx}}, ram_dina[12 * 8 +: 4 * 8]};
        end
        5'b00101: begin
            ram_lo_wea <= {ram_wea[0 +: 11], 5'b0};
            ram_hi_wea <= {11'b0, ram_wea[11 +: 5]};
            ram_lo_dina <= {ram_dina[0 +: 11 * 8], {5{8'bx}}};
            ram_hi_dina <= {{11{8'bx}}, ram_dina[11 * 8 +: 5 * 8]};
        end
        5'b00110: begin
            ram_lo_wea <= {ram_wea[0 +: 10], 6'b0};
            ram_hi_wea <= {10'b0, ram_wea[10 +: 6]};
            ram_lo_dina <= {ram_dina[0 +: 10 * 8], {6{8'bx}}};
            ram_hi_dina <= {{10{8'bx}}, ram_dina[10 * 8 +: 6 * 8]};
        end
        5'b00111: begin
            ram_lo_wea <= {ram_wea[0 +: 9], 7'b0};
            ram_hi_wea <= {9'b0, ram_wea[9 +: 7]};
            ram_lo_dina <= {ram_dina[0 +: 9 * 8], {7{8'bx}}};
            ram_hi_dina <= {{9{8'bx}}, ram_dina[9 * 8 +: 7 * 8]};
        end
        5'b01000: begin
            ram_lo_wea <= {ram_wea[0 +: 8], 8'b0};
            ram_hi_wea <= {8'b0, ram_wea[8 +: 8]};
            ram_lo_dina <= {ram_dina[0 +: 8 * 8], {8{8'bx}}};
            ram_hi_dina <= {{8{8'bx}}, ram_dina[8 * 8 +: 8 * 8]};
        end
        5'b01001: begin
            ram_lo_wea <= {ram_wea[0 +: 7], 9'b0};
            ram_hi_wea <= {7'b0, ram_wea[7 +: 9]};
            ram_lo_dina <= {ram_dina[0 +: 7 * 8], {9{8'bx}}};
            ram_hi_dina <= {{7{8'bx}}, ram_dina[7 * 8 +: 9 * 8]};
        end
        5'b01010: begin
            ram_lo_wea <= {ram_wea[0 +: 6], 10'b0};
            ram_hi_wea <= {6'b0, ram_wea[6 +: 10]};
            ram_lo_dina <= {ram_dina[0 +: 6 * 8], {10{8'bx}}};
            ram_hi_dina <= {{6{8'bx}}, ram_dina[6 * 8 +: 10 * 8]};
        end
        5'b01011: begin
            ram_lo_wea <= {ram_wea[0 +: 5], 11'b0};
            ram_hi_wea <= {5'b0, ram_wea[5 +: 11]};
            ram_lo_dina <= {ram_dina[0 +: 5 * 8], {11{8'bx}}};
            ram_hi_dina <= {{5{8'bx}}, ram_dina[5 * 8 +: 11 * 8]};
        end
        5'b01100: begin
            ram_lo_wea <= {ram_wea[0 +: 4], 12'b0};
            ram_hi_wea <= {4'b0, ram_wea[4 +: 12]};
            ram_lo_dina <= {ram_dina[0 +: 4 * 8], {12{8'bx}}};
            ram_hi_dina <= {{4{8'bx}}, ram_dina[4 * 8 +: 12 * 8]};
        end
        5'b01101: begin
            ram_lo_wea <= {ram_wea[0 +: 3], 13'b0};
            ram_hi_wea <= {3'b0, ram_wea[3 +: 13]};
            ram_lo_dina <= {ram_dina[0 +: 3 * 8], {13{8'bx}}};
            ram_hi_dina <= {{3{8'bx}}, ram_dina[3 * 8 +: 13 * 8]};
        end
        5'b01110: begin
            ram_lo_wea <= {ram_wea[0 +: 2], 14'b0};
            ram_hi_wea <= {2'b0, ram_wea[2 +: 14]};
            ram_lo_dina <= {ram_dina[0 +: 2 * 8], {14{8'bx}}};
            ram_hi_dina <= {{2{8'bx}}, ram_dina[2 * 8 +: 14 * 8]};
        end
        5'b01111: begin
            ram_lo_wea <= {ram_wea[0 +: 1], 15'b0};
            ram_hi_wea <= {1'b0, ram_wea[1 +: 15]};
            ram_lo_dina <= {ram_dina[0 +: 1 * 8], {15{8'bx}}};
            ram_hi_dina <= {{1{8'bx}}, ram_dina[1 * 8 +: 15 * 8]};
        end
        5'b10001: begin
            ram_hi_wea <= {ram_wea[0 +: 15], 1'b0};
            ram_lo_wea <= {15'b0, ram_wea[15 +: 1]};
            ram_hi_dina <= {ram_dina[0 +: 15 * 8], {1{8'bx}}};
            ram_lo_dina <= {{15{8'bx}}, ram_dina[15 * 8 +: 1 * 8]};
        end
        5'b10010: begin
            ram_hi_wea <= {ram_wea[0 +: 14], 2'b0};
            ram_lo_wea <= {14'b0, ram_wea[14 +: 2]};
            ram_hi_dina <= {ram_dina[0 +: 14 * 8], {2{8'bx}}};
            ram_lo_dina <= {{14{8'bx}}, ram_dina[14 * 8 +: 2 * 8]};
        end
        5'b10011: begin
            ram_hi_wea <= {ram_wea[0 +: 13], 3'b0};
            ram_lo_wea <= {13'b0, ram_wea[13 +: 3]};
            ram_hi_dina <= {ram_dina[0 +: 13 * 8], {3{8'bx}}};
            ram_lo_dina <= {{13{8'bx}}, ram_dina[13 * 8 +: 3 * 8]};
        end
        5'b10100: begin
            ram_hi_wea <= {ram_wea[0 +: 12], 4'b0};
            ram_lo_wea <= {12'b0, ram_wea[12 +: 4]};
            ram_hi_dina <= {ram_dina[0 +: 12 * 8], {4{8'bx}}};
            ram_lo_dina <= {{12{8'bx}}, ram_dina[12 * 8 +: 4 * 8]};
        end
        5'b10101: begin
            ram_hi_wea <= {ram_wea[0 +: 11], 5'b0};
            ram_lo_wea <= {11'b0, ram_wea[11 +: 5]};
            ram_hi_dina <= {ram_dina[0 +: 11 * 8], {5{8'bx}}};
            ram_lo_dina <= {{11{8'bx}}, ram_dina[11 * 8 +: 5 * 8]};
        end
        5'b10110: begin
            ram_hi_wea <= {ram_wea[0 +: 10], 6'b0};
            ram_lo_wea <= {10'b0, ram_wea[10 +: 6]};
            ram_hi_dina <= {ram_dina[0 +: 10 * 8], {6{8'bx}}};
            ram_lo_dina <= {{10{8'bx}}, ram_dina[10 * 8 +: 6 * 8]};
        end
        5'b10111: begin
            ram_hi_wea <= {ram_wea[0 +: 9], 7'b0};
            ram_lo_wea <= {9'b0, ram_wea[9 +: 7]};
            ram_hi_dina <= {ram_dina[0 +: 9 * 8], {7{8'bx}}};
            ram_lo_dina <= {{9{8'bx}}, ram_dina[9 * 8 +: 7 * 8]};
        end
        5'b11000: begin
            ram_hi_wea <= {ram_wea[0 +: 8], 8'b0};
            ram_lo_wea <= {8'b0, ram_wea[8 +: 8]};
            ram_hi_dina <= {ram_dina[0 +: 8 * 8], {8{8'bx}}};
            ram_lo_dina <= {{8{8'bx}}, ram_dina[8 * 8 +: 8 * 8]};
        end
        5'b11001: begin
            ram_hi_wea <= {ram_wea[0 +: 7], 9'b0};
            ram_lo_wea <= {7'b0, ram_wea[7 +: 9]};
            ram_hi_dina <= {ram_dina[0 +: 7 * 8], {9{8'bx}}};
            ram_lo_dina <= {{7{8'bx}}, ram_dina[7 * 8 +: 9 * 8]};
        end
        5'b11010: begin
            ram_hi_wea <= {ram_wea[0 +: 6], 10'b0};
            ram_lo_wea <= {6'b0, ram_wea[6 +: 10]};
            ram_hi_dina <= {ram_dina[0 +: 6 * 8], {10{8'bx}}};
            ram_lo_dina <= {{6{8'bx}}, ram_dina[6 * 8 +: 10 * 8]};
        end
        5'b11011: begin
            ram_hi_wea <= {ram_wea[0 +: 5], 11'b0};
            ram_lo_wea <= {5'b0, ram_wea[5 +: 11]};
            ram_hi_dina <= {ram_dina[0 +: 5 * 8], {11{8'bx}}};
            ram_lo_dina <= {{5{8'bx}}, ram_dina[5 * 8 +: 11 * 8]};
        end
        5'b11100: begin
            ram_hi_wea <= {ram_wea[0 +: 4], 12'b0};
            ram_lo_wea <= {4'b0, ram_wea[4 +: 12]};
            ram_hi_dina <= {ram_dina[0 +: 4 * 8], {12{8'bx}}};
            ram_lo_dina <= {{4{8'bx}}, ram_dina[4 * 8 +: 12 * 8]};
        end
        5'b11101: begin
            ram_hi_wea <= {ram_wea[0 +: 3], 13'b0};
            ram_lo_wea <= {3'b0, ram_wea[3 +: 13]};
            ram_hi_dina <= {ram_dina[0 +: 3 * 8], {13{8'bx}}};
            ram_lo_dina <= {{3{8'bx}}, ram_dina[3 * 8 +: 13 * 8]};
        end
        5'b11110: begin
            ram_hi_wea <= {ram_wea[0 +: 2], 14'b0};
            ram_lo_wea <= {2'b0, ram_wea[2 +: 14]};
            ram_hi_dina <= {ram_dina[0 +: 2 * 8], {14{8'bx}}};
            ram_lo_dina <= {{2{8'bx}}, ram_dina[2 * 8 +: 14 * 8]};
        end
        5'b11111: begin
            ram_hi_wea <= {ram_wea[0 +: 1], 15'b0};
            ram_lo_wea <= {1'b0, ram_wea[1 +: 15]};
            ram_hi_dina <= {ram_dina[0 +: 1 * 8], {15{8'bx}}};
            ram_lo_dina <= {{1{8'bx}}, ram_dina[1 * 8 +: 15 * 8]};
        end
        endcase
    end



    always @(*) begin

        case (ram_byteaddrb[4])
        1'b0: begin
            ram_lo_addrb <= ram_byteaddrb[BYTEADDR_WIDTH - 1 : 5];
            ram_hi_addrb <= ram_byteaddrb[BYTEADDR_WIDTH - 1 : 5];
        end
        1'b1: begin
            ram_lo_addrb <= ram_byteaddrb[BYTEADDR_WIDTH - 1 : 5] + 1;
            ram_hi_addrb <= ram_byteaddrb[BYTEADDR_WIDTH - 1 : 5];
        end
        endcase 
        
        case (ram_byteaddrb[4 : 0]) 
        5'b00000: begin
            ram_lo_web <= ram_web;
            ram_hi_web <= 0;
            ram_lo_dinb <= ram_dinb;
            ram_hi_dinb <= 0;
        end
        5'b10000: begin
            ram_lo_web <= 0;
            ram_hi_web <= ram_web;
            ram_lo_dinb <= 0;
            ram_hi_dinb <= ram_dinb;
        end
        5'b00001: begin
            ram_lo_web <= {ram_web[0 +: 15], 1'b0};
            ram_hi_web <= {15'b0, ram_web[15 +: 1]};
            ram_lo_dinb <= {ram_dinb[0 +: 15 * 8], {1{8'bx}}};
            ram_hi_dinb <= {{15{8'bx}}, ram_dinb[15 * 8 +: 1 * 8]};
        end
        5'b00010: begin
            ram_lo_web <= {ram_web[0 +: 14], 2'b0};
            ram_hi_web <= {14'b0, ram_web[14 +: 2]};
            ram_lo_dinb <= {ram_dinb[0 +: 14 * 8], {2{8'bx}}};
            ram_hi_dinb <= {{14{8'bx}}, ram_dinb[14 * 8 +: 2 * 8]};
        end
        5'b00011: begin
            ram_lo_web <= {ram_web[0 +: 13], 3'b0};
            ram_hi_web <= {13'b0, ram_web[13 +: 3]};
            ram_lo_dinb <= {ram_dinb[0 +: 13 * 8], {3{8'bx}}};
            ram_hi_dinb <= {{13{8'bx}}, ram_dinb[13 * 8 +: 3 * 8]};
        end
        5'b00100: begin
            ram_lo_web <= {ram_web[0 +: 12], 4'b0};
            ram_hi_web <= {12'b0, ram_web[12 +: 4]};
            ram_lo_dinb <= {ram_dinb[0 +: 12 * 8], {4{8'bx}}};
            ram_hi_dinb <= {{12{8'bx}}, ram_dinb[12 * 8 +: 4 * 8]};
        end
        5'b00101: begin
            ram_lo_web <= {ram_web[0 +: 11], 5'b0};
            ram_hi_web <= {11'b0, ram_web[11 +: 5]};
            ram_lo_dinb <= {ram_dinb[0 +: 11 * 8], {5{8'bx}}};
            ram_hi_dinb <= {{11{8'bx}}, ram_dinb[11 * 8 +: 5 * 8]};
        end
        5'b00110: begin
            ram_lo_web <= {ram_web[0 +: 10], 6'b0};
            ram_hi_web <= {10'b0, ram_web[10 +: 6]};
            ram_lo_dinb <= {ram_dinb[0 +: 10 * 8], {6{8'bx}}};
            ram_hi_dinb <= {{10{8'bx}}, ram_dinb[10 * 8 +: 6 * 8]};
        end
        5'b00111: begin
            ram_lo_web <= {ram_web[0 +: 9], 7'b0};
            ram_hi_web <= {9'b0, ram_web[9 +: 7]};
            ram_lo_dinb <= {ram_dinb[0 +: 9 * 8], {7{8'bx}}};
            ram_hi_dinb <= {{9{8'bx}}, ram_dinb[9 * 8 +: 7 * 8]};
        end
        5'b01000: begin
            ram_lo_web <= {ram_web[0 +: 8], 8'b0};
            ram_hi_web <= {8'b0, ram_web[8 +: 8]};
            ram_lo_dinb <= {ram_dinb[0 +: 8 * 8], {8{8'bx}}};
            ram_hi_dinb <= {{8{8'bx}}, ram_dinb[8 * 8 +: 8 * 8]};
        end
        5'b01001: begin
            ram_lo_web <= {ram_web[0 +: 7], 9'b0};
            ram_hi_web <= {7'b0, ram_web[7 +: 9]};
            ram_lo_dinb <= {ram_dinb[0 +: 7 * 8], {9{8'bx}}};
            ram_hi_dinb <= {{7{8'bx}}, ram_dinb[7 * 8 +: 9 * 8]};
        end
        5'b01010: begin
            ram_lo_web <= {ram_web[0 +: 6], 10'b0};
            ram_hi_web <= {6'b0, ram_web[6 +: 10]};
            ram_lo_dinb <= {ram_dinb[0 +: 6 * 8], {10{8'bx}}};
            ram_hi_dinb <= {{6{8'bx}}, ram_dinb[6 * 8 +: 10 * 8]};
        end
        5'b01011: begin
            ram_lo_web <= {ram_web[0 +: 5], 11'b0};
            ram_hi_web <= {5'b0, ram_web[5 +: 11]};
            ram_lo_dinb <= {ram_dinb[0 +: 5 * 8], {11{8'bx}}};
            ram_hi_dinb <= {{5{8'bx}}, ram_dinb[5 * 8 +: 11 * 8]};
        end
        5'b01100: begin
            ram_lo_web <= {ram_web[0 +: 4], 12'b0};
            ram_hi_web <= {4'b0, ram_web[4 +: 12]};
            ram_lo_dinb <= {ram_dinb[0 +: 4 * 8], {12{8'bx}}};
            ram_hi_dinb <= {{4{8'bx}}, ram_dinb[4 * 8 +: 12 * 8]};
        end
        5'b01101: begin
            ram_lo_web <= {ram_web[0 +: 3], 13'b0};
            ram_hi_web <= {3'b0, ram_web[3 +: 13]};
            ram_lo_dinb <= {ram_dinb[0 +: 3 * 8], {13{8'bx}}};
            ram_hi_dinb <= {{3{8'bx}}, ram_dinb[3 * 8 +: 13 * 8]};
        end
        5'b01110: begin
            ram_lo_web <= {ram_web[0 +: 2], 14'b0};
            ram_hi_web <= {2'b0, ram_web[2 +: 14]};
            ram_lo_dinb <= {ram_dinb[0 +: 2 * 8], {14{8'bx}}};
            ram_hi_dinb <= {{2{8'bx}}, ram_dinb[2 * 8 +: 14 * 8]};
        end
        5'b01111: begin
            ram_lo_web <= {ram_web[0 +: 1], 15'b0};
            ram_hi_web <= {1'b0, ram_web[1 +: 15]};
            ram_lo_dinb <= {ram_dinb[0 +: 1 * 8], {15{8'bx}}};
            ram_hi_dinb <= {{1{8'bx}}, ram_dinb[1 * 8 +: 15 * 8]};
        end
        5'b10001: begin
            ram_hi_web <= {ram_web[0 +: 15], 1'b0};
            ram_lo_web <= {15'b0, ram_web[15 +: 1]};
            ram_hi_dinb <= {ram_dinb[0 +: 15 * 8], {1{8'bx}}};
            ram_lo_dinb <= {{15{8'bx}}, ram_dinb[15 * 8 +: 1 * 8]};
        end
        5'b10010: begin
            ram_hi_web <= {ram_web[0 +: 14], 2'b0};
            ram_lo_web <= {14'b0, ram_web[14 +: 2]};
            ram_hi_dinb <= {ram_dinb[0 +: 14 * 8], {2{8'bx}}};
            ram_lo_dinb <= {{14{8'bx}}, ram_dinb[14 * 8 +: 2 * 8]};
        end
        5'b10011: begin
            ram_hi_web <= {ram_web[0 +: 13], 3'b0};
            ram_lo_web <= {13'b0, ram_web[13 +: 3]};
            ram_hi_dinb <= {ram_dinb[0 +: 13 * 8], {3{8'bx}}};
            ram_lo_dinb <= {{13{8'bx}}, ram_dinb[13 * 8 +: 3 * 8]};
        end
        5'b10100: begin
            ram_hi_web <= {ram_web[0 +: 12], 4'b0};
            ram_lo_web <= {12'b0, ram_web[12 +: 4]};
            ram_hi_dinb <= {ram_dinb[0 +: 12 * 8], {4{8'bx}}};
            ram_lo_dinb <= {{12{8'bx}}, ram_dinb[12 * 8 +: 4 * 8]};
        end
        5'b10101: begin
            ram_hi_web <= {ram_web[0 +: 11], 5'b0};
            ram_lo_web <= {11'b0, ram_web[11 +: 5]};
            ram_hi_dinb <= {ram_dinb[0 +: 11 * 8], {5{8'bx}}};
            ram_lo_dinb <= {{11{8'bx}}, ram_dinb[11 * 8 +: 5 * 8]};
        end
        5'b10110: begin
            ram_hi_web <= {ram_web[0 +: 10], 6'b0};
            ram_lo_web <= {10'b0, ram_web[10 +: 6]};
            ram_hi_dinb <= {ram_dinb[0 +: 10 * 8], {6{8'bx}}};
            ram_lo_dinb <= {{10{8'bx}}, ram_dinb[10 * 8 +: 6 * 8]};
        end
        5'b10111: begin
            ram_hi_web <= {ram_web[0 +: 9], 7'b0};
            ram_lo_web <= {9'b0, ram_web[9 +: 7]};
            ram_hi_dinb <= {ram_dinb[0 +: 9 * 8], {7{8'bx}}};
            ram_lo_dinb <= {{9{8'bx}}, ram_dinb[9 * 8 +: 7 * 8]};
        end
        5'b11000: begin
            ram_hi_web <= {ram_web[0 +: 8], 8'b0};
            ram_lo_web <= {8'b0, ram_web[8 +: 8]};
            ram_hi_dinb <= {ram_dinb[0 +: 8 * 8], {8{8'bx}}};
            ram_lo_dinb <= {{8{8'bx}}, ram_dinb[8 * 8 +: 8 * 8]};
        end
        5'b11001: begin
            ram_hi_web <= {ram_web[0 +: 7], 9'b0};
            ram_lo_web <= {7'b0, ram_web[7 +: 9]};
            ram_hi_dinb <= {ram_dinb[0 +: 7 * 8], {9{8'bx}}};
            ram_lo_dinb <= {{7{8'bx}}, ram_dinb[7 * 8 +: 9 * 8]};
        end
        5'b11010: begin
            ram_hi_web <= {ram_web[0 +: 6], 10'b0};
            ram_lo_web <= {6'b0, ram_web[6 +: 10]};
            ram_hi_dinb <= {ram_dinb[0 +: 6 * 8], {10{8'bx}}};
            ram_lo_dinb <= {{6{8'bx}}, ram_dinb[6 * 8 +: 10 * 8]};
        end
        5'b11011: begin
            ram_hi_web <= {ram_web[0 +: 5], 11'b0};
            ram_lo_web <= {5'b0, ram_web[5 +: 11]};
            ram_hi_dinb <= {ram_dinb[0 +: 5 * 8], {11{8'bx}}};
            ram_lo_dinb <= {{5{8'bx}}, ram_dinb[5 * 8 +: 11 * 8]};
        end
        5'b11100: begin
            ram_hi_web <= {ram_web[0 +: 4], 12'b0};
            ram_lo_web <= {4'b0, ram_web[4 +: 12]};
            ram_hi_dinb <= {ram_dinb[0 +: 4 * 8], {12{8'bx}}};
            ram_lo_dinb <= {{4{8'bx}}, ram_dinb[4 * 8 +: 12 * 8]};
        end
        5'b11101: begin
            ram_hi_web <= {ram_web[0 +: 3], 13'b0};
            ram_lo_web <= {3'b0, ram_web[3 +: 13]};
            ram_hi_dinb <= {ram_dinb[0 +: 3 * 8], {13{8'bx}}};
            ram_lo_dinb <= {{3{8'bx}}, ram_dinb[3 * 8 +: 13 * 8]};
        end
        5'b11110: begin
            ram_hi_web <= {ram_web[0 +: 2], 14'b0};
            ram_lo_web <= {2'b0, ram_web[2 +: 14]};
            ram_hi_dinb <= {ram_dinb[0 +: 2 * 8], {14{8'bx}}};
            ram_lo_dinb <= {{2{8'bx}}, ram_dinb[2 * 8 +: 14 * 8]};
        end
        5'b11111: begin
            ram_hi_web <= {ram_web[0 +: 1], 15'b0};
            ram_lo_web <= {1'b0, ram_web[1 +: 15]};
            ram_hi_dinb <= {ram_dinb[0 +: 1 * 8], {15{8'bx}}};
            ram_lo_dinb <= {{1{8'bx}}, ram_dinb[1 * 8 +: 15 * 8]};
        end
        endcase
    end



    ram #(
        .RAM_DEPTH(RAM_DEPTH)
    ) ram_lo_inst (
        .clk(clk),

        .ram_douta(ram_lo_douta),
        .ram_doutb(ram_lo_doutb),
        .ram_addra(ram_lo_addra),
        .ram_addrb(ram_lo_addrb),
        .ram_dina(ram_lo_dina),
        .ram_dinb(ram_lo_dinb),
        .ram_wea(ram_lo_wea),
        .ram_web(ram_lo_web),
        .ram_ena(ram_ena),
        .ram_enb(ram_enb)
    );

    ram #(
        .RAM_DEPTH(RAM_DEPTH)
    ) ram_hi_inst (
        .clk(clk),

        .ram_douta(ram_hi_douta),
        .ram_doutb(ram_hi_doutb),
        .ram_addra(ram_hi_addra),
        .ram_addrb(ram_hi_addrb),
        .ram_dina(ram_hi_dina),
        .ram_dinb(ram_hi_dinb),
        .ram_wea(ram_hi_wea),
        .ram_web(ram_hi_web),
        .ram_ena(ram_ena),
        .ram_enb(ram_enb)
    );
endmodule
