/*
 * Top module for NES debugger
 */

module NESDebuggerTop(
    input   i_clk_5mhz,             // NES clock
    input   i_clk_25mhz,            // VGA clock
    input   i_reset_n,
    
    // SPI interface
    input           i_spi_cs_n,
    input           i_spi_clk,      // SPI CLK: clock signal from controller
    output          o_spi_cipo,     // SPI CIPO: tri-state in top module: high-z when cs is positive
    input           i_spi_copi,     // SPI CPOI: only process when cs is negative

    // VGA output
    output [7:0]    o_vga_red,
    output [7:0]    o_vga_green,
    output [7:0]    o_vga_blue,
    output          o_vga_hsync,
    output          o_vga_vsync
);

// reset for NES design
wire w_nes_reset_n;

// synchronisation between 25mhz videooutput and 5mhz NES
// where NES clock-enable is disabled at the end of a frame until the video output is ready for it to continue
//
// NES clock should be disabled when it is about to start a new frame
// until r_videooutput_sync is set to 1
reg r_videooutput_sync;

// debug communication
localparam RW_WRITE = 0;
localparam RW_READ = 1;

wire [7:0] w_rx_byte;
wire w_rx_dv;

wire [7:0] w_tx_byte;
wire w_tx_dv;

// unused DEBUG pins
/* verilator lint_off UNUSED */
wire w_debug_rx_buffered_0;
wire w_debug_rx_buffered_1;
wire w_debug_rx_buffered_2;
wire [2:0] w_debug_tx_bit_index;
wire [2:0] w_debug_rx_bit_index;
wire w_debug_active;
wire [7:0] w_debug_tx_byte_buffered;
/* verilator lint_on UNUSED */

SPIPeripheral spi(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),
    
    .o_rx_byte(w_rx_byte),
    .o_rx_dv(w_rx_dv),
    .i_tx_dv(w_tx_dv),
    .i_tx_byte(w_tx_byte),

    .i_spi_clk(i_spi_clk),
    .o_spi_cipo(o_spi_cipo),
    .i_spi_copi(i_spi_copi),
    .i_spi_cs_n(i_spi_cs_n),

    .o_debug_rx_buffered_0(w_debug_rx_buffered_0),
    .o_debug_rx_buffered_1(w_debug_rx_buffered_1),
    .o_debug_rx_buffered_2(w_debug_rx_buffered_2),
    .o_debug_tx_bit_index(w_debug_tx_bit_index),
    .o_debug_rx_bit_index(w_debug_rx_bit_index),
    .o_debug_active(w_debug_active),
    .o_debug_tx_byte_buffered(w_debug_tx_byte_buffered)
);

wire [15:0] w_debugger_mem_address;
wire w_debugger_mem_rw;
wire w_debugger_mem_en;
wire [7:0] w_debugger_mem_data_wr;
reg [7:0] r_debugger_mem_data_rd;

wire [15:0] w_value_id;
wire w_value_rw;
wire w_value_en;
wire [15:0] w_value_data_wr;
wire [15:0] w_value_data_rd;

// unused DEBUG pins
/* verilator lint_off UNUSED */
wire [7:0] w_debug_cmd;
wire [15:0] w_debug_cmd_bytes_remaining;
/* verilator lint_on UNUSED */

NESDebugger debugger(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n & ~i_spi_cs_n),
    
    .i_rx_dv(w_rx_dv),
    .i_rx_byte(w_rx_byte),
    
    .o_tx_dv(w_tx_dv),
    .o_tx_byte(w_tx_byte),
    
    .o_mem_address(w_debugger_mem_address),
    .o_mem_rw(w_debugger_mem_rw),
    .o_mem_en(w_debugger_mem_en),
    .o_mem_data(w_debugger_mem_data_wr),
    .i_mem_data(r_debugger_mem_data_rd),

    .o_value_id(w_value_id),
    .o_value_rw(w_value_rw),
    .o_value_en(w_value_en),
    .o_value_data(w_value_data_wr),
    .i_value_data(w_value_data_rd),

    .o_debug_cmd(w_debug_cmd),
    .o_debug_cmd_bytes_remaining(w_debug_cmd_bytes_remaining)
);

//
// Memory Pool Wiring
//

// wire used by debugger to select which memory pool it is accessing
wire [1:0] w_debugger_memory_pool;
localparam MEMORY_POOL_PRG = 0;
localparam MEMORY_POOL_RAM = 1;
localparam MEMORY_POOL_PATTERNTABLE = 2;
localparam MEMORY_POOL_NAMETABLE = 3;

wire [7:0] w_debugger_mem_prg_data_rd;
wire [7:0] w_debugger_mem_ram_data_rd;
wire [7:0] w_debugger_mem_patterntable_data_rd;
wire [7:0] w_debugger_mem_nametable_data_rd;

always @(*)
begin

    case (w_debugger_memory_pool)
    MEMORY_POOL_PRG: r_debugger_mem_data_rd = w_debugger_mem_prg_data_rd;
    MEMORY_POOL_RAM: r_debugger_mem_data_rd = w_debugger_mem_ram_data_rd;
    MEMORY_POOL_PATTERNTABLE: r_debugger_mem_data_rd = w_debugger_mem_patterntable_data_rd;
    MEMORY_POOL_NAMETABLE: r_debugger_mem_data_rd = w_debugger_mem_nametable_data_rd;
    default: r_debugger_mem_data_rd = 0;
    endcase
end

// PRG - CPU6502 program
wire w_mem_prg_en;
wire w_mem_prg_wea;
wire [15:0] w_mem_prg_address;
wire [7:0] w_mem_prg_data_rd;
wire [7:0] w_mem_prg_data_wr;

wire w_nes_prg_en;
wire w_nes_prg_rw;
wire [15:0] w_nes_prg_address;
wire [7:0] w_nes_prg_data_rd;
wire [7:0] w_nes_prg_data_wr;

assign w_nes_prg_rw = RW_READ;
assign w_nes_prg_data_wr = 0;

// RAM - R/W RAM for CPU6502
wire w_mem_ram_en;
wire w_mem_ram_wea;
wire [15:0] w_mem_ram_address;
wire [7:0] w_mem_ram_data_rd;
wire [7:0] w_mem_ram_data_wr;

wire w_nes_ram_en;
wire w_nes_ram_rw;
wire [15:0] w_nes_ram_address;
wire [7:0] w_nes_ram_data_rd;
wire [7:0] w_nes_ram_data_wr;

// PATTERNTABLE - graphics data for PPU
wire w_mem_patterntable_en;
wire w_mem_patterntable_wea;
wire [15:0] w_mem_patterntable_address;
wire [7:0] w_mem_patterntable_data_rd;
wire [7:0] w_mem_patterntable_data_wr;

wire w_nes_patterntable_en;
wire w_nes_patterntable_rw;
wire [13:0] w_nes_patterntable_address;
wire [7:0] w_nes_patterntable_data_rd;
wire [7:0] w_nes_patterntable_data_wr;

assign w_nes_patterntable_data_wr = 0;

// NAMETABLE - background tile data, managed by PPU
wire w_mem_nametable_en;
wire w_mem_nametable_wea;
wire [15:0] w_mem_nametable_address;
wire [7:0] w_mem_nametable_data_rd;
wire [7:0] w_mem_nametable_data_wr;

wire w_nes_nametable_en;
wire w_nes_nametable_rw;
wire [13:0] w_nes_nametable_address;
wire [7:0] w_nes_nametable_data_rd;
wire [7:0] w_nes_nametable_data_wr;

//
// NES
//

wire [7:0] w_nes_video_red;
wire [7:0] w_nes_video_green;
wire [7:0] w_nes_video_blue;
/* verilator lint_off UNUSED */
wire [8:0] w_nes_video_x;                   // note: could these be used to help validate input to FIFO?
wire [8:0] w_nes_video_y;
/* verilator lint_on UNUSED */
wire w_nes_video_visible;

// NES clock enable
reg r_nes_ce;

localparam [8:0] NES_SCREEN_WIDTH = 341;
localparam [8:0] NES_SCREEN_HEIGHT = 262;

always @(negedge i_reset_n or negedge i_clk_5mhz)
begin
    if (!i_reset_n)
    begin
        r_nes_ce = 1;
    end
    else
    begin
        // pause NES rendering just-before starting new frame
        // UNTIL videooutput sets 'sync' signal
        if ((w_nes_video_x >= (NES_SCREEN_WIDTH-3)) && (w_nes_video_x <= (NES_SCREEN_WIDTH-1)) && (w_nes_video_y == (NES_SCREEN_HEIGHT-1)) && (r_videooutput_sync == 0))
        begin
            r_nes_ce <= 0;
        end
        else
        begin
            r_nes_ce <= 1;
        end
    end
end


// NES debug ports
wire [7:0] w_cpu_debug_ir;
wire w_cpu_debug_error;
wire w_cpu_debug_rw;
wire [15:0] w_cpu_debug_address;
wire [3:0] w_cpu_debug_tcu;
wire w_cpu_debug_clk_en;
wire w_cpu_debug_sync;
wire w_ppu_debug_clk_en;


/* verilator lint_off PINMISSING */
NES nes(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n & w_nes_reset_n),

    // clock enable
    .i_ce(r_nes_ce),

    // video output
    .o_video_red(w_nes_video_red),
    .o_video_green(w_nes_video_green),
    .o_video_blue(w_nes_video_blue),
    .o_video_x(w_nes_video_x),
    .o_video_y(w_nes_video_y),
    .o_video_visible(w_nes_video_visible),

    // controller
    // o_controller_latch           // TODO: register when cpu en, falling clock edge
    // o_controller_clk             // TODO: register when cpu en, falling clock edge
    .i_controller_1(1),             // 1 = not pressed

    // CPU memory access - RAM
    .o_cs_ram(w_nes_ram_en),
    .o_address_ram(w_nes_ram_address),
    .o_rw_ram(w_nes_ram_rw),
    .o_data_ram(w_nes_ram_data_wr),
    .i_data_ram(w_nes_ram_data_rd),

    // CPU memory access - PRG
    .o_cs_prg(w_nes_prg_en),
    .o_address_prg(w_nes_prg_address),
    .i_data_prg(w_nes_prg_data_rd),

    // PPU memory access - Pattern Table
    .o_cs_patterntable(w_nes_patterntable_en),
    .i_data_patterntable(w_nes_patterntable_data_rd),
    .o_rw_patterntable(w_nes_patterntable_rw),
    .o_address_patterntable(w_nes_patterntable_address),

    // PPU memory access - Nametable
    .o_cs_nametable(w_nes_nametable_en),
    .i_data_nametable(w_nes_nametable_data_rd),
    .o_data_nametable(w_nes_nametable_data_wr),
    .o_rw_nametable(w_nes_nametable_rw),
    .o_address_nametable(w_nes_nametable_address),
    
    // debugging
    .o_cpu_debug_ir(w_cpu_debug_ir),
    .o_cpu_debug_error(w_cpu_debug_error),
    .o_cpu_debug_rw(w_cpu_debug_rw),
    .o_cpu_debug_address(w_cpu_debug_address),
    .o_cpu_debug_tcu(w_cpu_debug_tcu),
    .o_cpu_debug_clk_en(w_cpu_debug_clk_en),
    .o_cpu_debug_sync(w_cpu_debug_sync),
    .o_ppu_debug_clk_en(w_ppu_debug_clk_en)
);
/* verilator lint_on PINMISSING */

//
// Values - control NES reset, profiler, and debugger memory access
//

reg r_is_value_wea;

always @(*)
begin
    r_is_value_wea = (w_value_rw == RW_WRITE);
end

wire [15:0] w_profiler_sample_data;
wire [15:0] w_profiler_sample_index;
wire [15:0] w_profiler_sample_data_index;
wire w_profiler_wen;

NESDebuggerValues values (
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),

    .i_ena(w_value_en),
    .i_wea(r_is_value_wea),
    .i_id(w_value_id),
    .i_data(w_value_data_wr),
    .o_data(w_value_data_rd),
    
    // profiler
    .o_profiler_wen(w_profiler_wen),
    .i_profiler_sample_data(w_profiler_sample_data),
    .o_profiler_sample_index(w_profiler_sample_index),
    .o_profiler_sample_data_index(w_profiler_sample_data_index),

    // nes reset
    .o_nes_reset_n(w_nes_reset_n),
    
    // debugger memory access
    .o_debugger_memory_pool(w_debugger_memory_pool)
);

//
// Memory
//

NESDebuggerMCU mcu_prg(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),

    // connection to NES
    .i_nes_en(w_nes_prg_en & w_cpu_debug_clk_en),
    .i_nes_rw(w_nes_prg_rw),
    .i_nes_address(w_nes_prg_address),
    .i_nes_data(w_nes_prg_data_wr),
    .o_nes_data(w_nes_prg_data_rd),

    // connections to debugger
    .i_debugger_en(w_debugger_mem_en && (w_debugger_memory_pool == MEMORY_POOL_PRG)),
    .i_debugger_rw(w_debugger_mem_rw),
    .i_debugger_address(w_debugger_mem_address),
    .i_debugger_data(w_debugger_mem_data_wr),
    .o_debugger_data(w_debugger_mem_prg_data_rd),

    // connections to PRG memory
    .o_mem_en(w_mem_prg_en),
    .o_mem_wea(w_mem_prg_wea),
    .o_mem_address(w_mem_prg_address),
    .o_mem_data(w_mem_prg_data_wr),
    .i_mem_data(w_mem_prg_data_rd)
);

Memory memory_prg (
  .i_clk(i_clk_5mhz),
  .i_ena(w_mem_prg_en),
  .i_wea(w_mem_prg_wea),
  .i_addr(w_mem_prg_address),
  .i_data(w_mem_prg_data_wr),
  .o_data(w_mem_prg_data_rd)
);

NESDebuggerMCU mcu_ram(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),

    // connection to NES
    .i_nes_en(w_nes_ram_en & w_cpu_debug_clk_en),           // JK: is clk_en required to avoid writing incorrect values?
    .i_nes_rw(w_nes_ram_rw),
    .i_nes_address(w_nes_ram_address),
    .i_nes_data(w_nes_ram_data_wr),
    .o_nes_data(w_nes_ram_data_rd),

    // connections to debugger
    .i_debugger_en(w_debugger_mem_en && (w_debugger_memory_pool == MEMORY_POOL_RAM)),
    .i_debugger_rw(w_debugger_mem_rw),
    .i_debugger_address(w_debugger_mem_address),
    .i_debugger_data(w_debugger_mem_data_wr),
    .o_debugger_data(w_debugger_mem_ram_data_rd),

    // connections to RAM memory
    .o_mem_en(w_mem_ram_en),
    .o_mem_wea(w_mem_ram_wea),
    .o_mem_address(w_mem_ram_address),
    .o_mem_data(w_mem_ram_data_wr),
    .i_mem_data(w_mem_ram_data_rd)
);

Memory memory_ram (
  .i_clk(i_clk_5mhz),
  .i_ena(w_mem_ram_en),
  .i_wea(w_mem_ram_wea),
  .i_addr(w_mem_ram_address),
  .i_data(w_mem_ram_data_wr),
  .o_data(w_mem_ram_data_rd)
);

NESDebuggerMCU mcu_patterntable(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),

    // connection to NES
    .i_nes_en(w_nes_patterntable_en),
    .i_nes_rw(w_nes_patterntable_rw),
    .i_nes_address({2'b0, w_nes_patterntable_address}),
    .i_nes_data(w_nes_patterntable_data_wr),
    .o_nes_data(w_nes_patterntable_data_rd),

    // connections to debugger
    .i_debugger_en(w_debugger_mem_en && (w_debugger_memory_pool == MEMORY_POOL_PATTERNTABLE)),
    .i_debugger_rw(w_debugger_mem_rw),
    .i_debugger_address(w_debugger_mem_address),
    .i_debugger_data(w_debugger_mem_data_wr),
    .o_debugger_data(w_debugger_mem_patterntable_data_rd),

    // connections to PATTERNTABLE memory
    .o_mem_en(w_mem_patterntable_en),
    .o_mem_wea(w_mem_patterntable_wea),
    .o_mem_address(w_mem_patterntable_address),
    .o_mem_data(w_mem_patterntable_data_wr),
    .i_mem_data(w_mem_patterntable_data_rd)
);

Memory memory_patterntable (
  .i_clk(i_clk_5mhz),
  .i_ena(w_mem_patterntable_en),
  .i_wea(w_mem_patterntable_wea),
  .i_addr(w_mem_patterntable_address),
  .i_data(w_mem_patterntable_data_wr),
  .o_data(w_mem_patterntable_data_rd)
);

NESDebuggerMCU mcu_nametable(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n),

    // connection to NES
    .i_nes_en(w_nes_nametable_en),
    .i_nes_rw(w_nes_nametable_rw),
    .i_nes_address({2'b0, w_nes_nametable_address}),
    .i_nes_data(w_nes_nametable_data_wr),
    .o_nes_data(w_nes_nametable_data_rd),

    // connections to debugger
    .i_debugger_en(w_debugger_mem_en && (w_debugger_memory_pool == MEMORY_POOL_NAMETABLE)),
    .i_debugger_rw(w_debugger_mem_rw),
    .i_debugger_address(w_debugger_mem_address),
    .i_debugger_data(w_debugger_mem_data_wr),
    .o_debugger_data(w_debugger_mem_nametable_data_rd),

    // connections to NAMETABLE memory
    .o_mem_en(w_mem_nametable_en),
    .o_mem_wea(w_mem_nametable_wea),
    .o_mem_address(w_mem_nametable_address),
    .o_mem_data(w_mem_nametable_data_wr),
    .i_mem_data(w_mem_nametable_data_rd)
);

Memory memory_nametable (
  .i_clk(i_clk_5mhz),
  .i_ena(w_mem_nametable_en),
  .i_wea(w_mem_nametable_wea),
  .i_addr(w_mem_nametable_address),
  .i_data(w_mem_nametable_data_wr),
  .o_data(w_mem_nametable_data_rd)
);

//
// VGA Output
//

wire w_vga_visible;
wire [10:0] w_vga_x;
wire [10:0] w_vga_y;
wire [7:0] w_vga_red;
wire [7:0] w_vga_green;
wire [7:0] w_vga_blue;
wire w_vga_reset_n;

VGAGenerator vga_generator(
    .i_clk(i_clk_25mhz),
    .i_reset_n(w_vga_reset_n),
    .o_x(w_vga_x),
    .o_y(w_vga_y),
    .o_visible(w_vga_visible)
);

VGAOutput vga_output(
    .i_clk(i_clk_25mhz),
    .i_reset_n(w_vga_reset_n),
    .i_visible(w_vga_visible),
    .i_x(w_vga_x),
    .i_y(w_vga_y),
    .i_red(w_vga_red),
    .i_green(w_vga_green),
    .i_blue(w_vga_blue),
    .o_vga_red(o_vga_red),
    .o_vga_green(o_vga_green),
    .o_vga_blue(o_vga_blue),
    .o_vga_hsync(o_vga_hsync),
    .o_vga_vsync(o_vga_vsync)
);


//
// CDC FIFO - Video signal from 5MHz CPU/PPU to 25MHz VGA
//

// experiment: cache nes video x/y at falling edge, ready for fifo to read on rising edge
reg [8:0] r_nes_video_x;
reg [8:0] r_nes_video_y;
reg r_nes_video_visible;
reg [7:0] r_nes_video_red;
reg [7:0] r_nes_video_green;
reg [7:0] r_nes_video_blue;

always @(negedge i_reset_n or negedge i_clk_5mhz)
begin
    if (!i_reset_n)
    begin
        r_nes_video_visible <= 0;
        r_nes_video_x <= 0;
        r_nes_video_y <= 0;
        
        r_nes_video_red <= 0;
        r_nes_video_green <= 0;
        r_nes_video_blue <= 0;
    end
    else
    begin
        r_nes_video_visible <= w_nes_video_visible;
        r_nes_video_x <= w_nes_video_x;
        r_nes_video_y <= w_nes_video_y;
        
        r_nes_video_red <= w_nes_video_red;
        r_nes_video_green <= w_nes_video_green;
        r_nes_video_blue <= w_nes_video_blue;
    end
end


wire w_fifo_pixel_valid;
wire [23:0] w_fifo_pixel_rgb;
wire [8:0] w_fifo_pixel_x;

reg [7:0] r_debug_counter_x;

FIFO video_fifo(
    .i_clk_5mhz(i_clk_5mhz),
    .i_clk_25mhz(i_clk_25mhz),
    .i_reset_n(i_reset_n),
    .i_video_x(w_nes_video_x),    
    .i_video_valid(r_nes_video_visible),
    
    .i_video_red((w_nes_video_x == r_debug_counter_x) ? 8'b11111111 : r_nes_video_red),
    .i_video_green((w_nes_video_x == r_debug_counter_x) ? 8'b11111111 : r_nes_video_green),
    .i_video_blue((w_nes_video_x == r_debug_counter_x) ? 8'b11111111 : r_nes_video_blue),
    
    // test - vertical red line at x==100
    //.i_video_red((r_nes_video_x == 100) ? 255 : 0),
    //.i_video_green(0),
    //.i_video_blue(0),

    .o_pixel_valid(w_fifo_pixel_valid),
    .o_pixel_x(w_fifo_pixel_x),
    .o_pixel_rgb(w_fifo_pixel_rgb)
);

// NOTE: what prevents video_output from rendering during v-blank?
//       do we just have to make sure that we feed video from 
//       NES at right time?



/* verilator lint_off PINMISSING */
VideoOutput video_output(
    .i_clk(i_clk_25mhz),
    .i_reset_n(i_reset_n),

    // data received from FIFO
    .i_pixel_valid(w_fifo_pixel_valid),
    .i_pixel_x(w_fifo_pixel_x),
    .i_pixel_rgb(w_fifo_pixel_rgb),

    // driving VGA pixel data
    .o_vga_reset_n(w_vga_reset_n),
    .i_vga_x(w_vga_x),
    .o_vga_red(w_vga_red),
    .o_vga_green(w_vga_green),
    .o_vga_blue(w_vga_blue)

    /*
    // debug
    output [8:0] o_debug_linebuffer_write_index,
    output o_debug_linebuffer_front,
    output o_debug_vga_visible
    */
);
/* verilator lint_on PINMISSING */

// 
// pause NES at end of frame, until videoutput is ready for the first row
//

wire w_videooutput_sync_posedge;

always @(negedge i_reset_n or posedge i_clk_5mhz)
begin
    if (!i_reset_n)
    begin
        r_videooutput_sync <= 0;
        r_debug_counter_x <= 0;
    end
    else if (w_videooutput_sync_posedge)
    begin
        r_videooutput_sync <= 1;
        r_debug_counter_x <= r_debug_counter_x + 1;
    end
    else if (w_nes_video_y == 0)
    begin
        r_videooutput_sync <= 0;
    end
end

Sync video_output_sync(
    .i_clk(i_clk_25mhz),
    .i_reset_n(i_reset_n),
    .i_data(w_vga_y >= 520),        // VGA height is 525
    .i_sync_clk(i_clk_5mhz),
    .o_sync_posedge(w_videooutput_sync_posedge)
);

//
// Profiler
//

wire [6:0] w_profiler_spacing;
assign w_profiler_spacing = 0;

NESProfiler profiler(
    .i_clk(i_clk_5mhz),
    .i_reset_n(i_reset_n & w_nes_reset_n),
    
    // Interface to Debugger
    .o_sample_data(w_profiler_sample_data),
    .i_sample_index(w_profiler_sample_index),
    .i_sample_data_index(w_profiler_sample_data_index),
    
    // Interface to NES
    .i_sample_data({
        w_videooutput_sync_posedge,             // : 1
        r_videooutput_sync,                     // : 1
        r_nes_ce,                               // : 1
        w_cpu_debug_clk_en,                     // : 1
        w_ppu_debug_clk_en,                     // : 1
        w_nes_video_x,                          // : 9
        w_nes_video_y,                          // : 9
        w_nes_visible,                          // : 1
        w_cpu_debug_sync,                       // : 1
        w_profiler_spacing                     
    }),

    // write enable
    .i_wen(w_profiler_wen)
);


endmodule
