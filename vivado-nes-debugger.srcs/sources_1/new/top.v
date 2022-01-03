`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.11.2021 17:58:02
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input   i_clk_100mhz,
    input   i_reset_n,
    
    // SPI interface
    input           i_spi_cs_n,
    input           i_spi_clk,      // SPI CLK: clock signal from controller
    output          o_spi_cipo,     // SPI CIPO: tri-state in top module: high-z when cs is positive
    input           i_spi_copi,     // SPI CPOI: only process when cs is negative
    
    // VGA interface
    output [3:0] o_vga_r,
    output [3:0] o_vga_g,
    output [3:0] o_vga_b,
    output o_vga_hs,
    output o_vga_vs 
    );
 
wire w_clk_5mhz; 
wire w_clk_locked;

clk_wiz_0 pll(
    .i_clk_100mhz(i_clk_100mhz),
    .resetn(i_reset_n),
    
    .o_clk_5mhz(w_clk_5mhz),
    .o_clk_25mhz(w_clk_25mhz),
    .o_locked(w_clk_locked)
 );
 
 NESDebuggerTop debuggerTop(
    .i_clk_5mhz(w_clk_5mhz),
    .i_clk_25mhz(w_clk_25mhz),
    .i_reset_n(i_reset_n & w_clk_locked),
    
    .i_spi_cs_n(i_spi_cs_n),
    .i_spi_clk(i_spi_clk),
    .o_spi_cipo(o_spi_cipo),
    .i_spi_copi(i_spi_copi),
    
    .o_vga_red(o_vga_r),
    .o_vga_green(o_vga_g),
    .o_vga_blue(o_vga_b),
    .o_vga_hsync(o_vga_hs),
    .o_vga_vsync(o_vga_vs)
 );
    
endmodule
