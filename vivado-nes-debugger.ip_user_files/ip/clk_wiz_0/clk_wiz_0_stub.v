// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
// Date        : Mon Dec 20 16:37:20 2021
// Host        : DESKTOP-H1KDTUU running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(o_clk_5mhz, resetn, o_locked, i_clk_100mhz)
/* synthesis syn_black_box black_box_pad_pin="o_clk_5mhz,resetn,o_locked,i_clk_100mhz" */;
  output o_clk_5mhz;
  input resetn;
  output o_locked;
  input i_clk_100mhz;
endmodule
