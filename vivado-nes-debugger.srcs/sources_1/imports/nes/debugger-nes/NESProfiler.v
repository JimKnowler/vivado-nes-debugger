module NESProfiler(
    input i_clk,
    input i_reset_n,
    
    // Interface to Debugger
    output [15:0] o_sample_data,
    input [15:0] i_sample_index,
    input [15:0] i_sample_data_index,
    
    // Interface to NES
    input [7:0] i_cpu_debug_ir,
    input i_cpu_debug_error,
    input i_cpu_debug_rw,
    input [15:0] i_cpu_debug_address,
    input [3:0] i_cpu_debug_tcu,
    input i_cpu_debug_clk_en,
    input i_cpu_debug_sync,
    
    // TODO: hook up these data signals to profiler
    input [7:0] i_nes_ram_data_wr,
    input [7:0] i_nes_ram_data_rd,
    input [7:0] i_nes_prg_data_rd
);

localparam MAX_NUM_SAMPLES = 4096;          // NOTE: this is configured in ProfilerMemory IP

reg [12:0] r_sample_write_index;
reg [31:0] r_sample_data_write;

// NES performs reads/writes at falling edge of clock
always @(negedge i_reset_n or negedge i_clk)
begin
    if (!i_reset_n)
    begin
        r_sample_write_index <= 0;
    end
    else
    begin
        if (r_sample_write_index < MAX_NUM_SAMPLES) begin
            r_sample_write_index <= r_sample_write_index + 1;
        end
        
        // useful for testing profiler    
        //r_sample_data_write = r_sample_write_index;
            
        r_sample_data_write <= { 
            i_cpu_debug_error,      // [31]
            i_cpu_debug_rw,         // [30]
            i_cpu_debug_clk_en,     // [29]
            i_cpu_debug_sync,       // [28]
            i_cpu_debug_tcu,        // [27:24]
            i_cpu_debug_ir,         // [23:16]
            i_cpu_debug_address     // [15:0]
        };
    end
end


reg r_sample_data_write_enable;

always @(*)
begin
    r_sample_data_write_enable = (r_sample_write_index < MAX_NUM_SAMPLES);
end

wire [31:0] w_sample_data_read;

NESProfilerMemory memory(
    // port A - write
    .clka(i_clk),
    .ena(1),
    .wea(r_sample_data_write_enable),
    .addra(r_sample_write_index[11:0]),
    .dina(r_sample_data_write),

    // port B - read
    .clkb(i_clk),
    .enb(1),      // input wire enb
    .addrb(i_sample_index[11:0]),
    .doutb(w_sample_data_read)
);

assign o_sample_data = (i_sample_data_index == 0) ? w_sample_data_read[15:0] : w_sample_data_read[31:16];

endmodule
