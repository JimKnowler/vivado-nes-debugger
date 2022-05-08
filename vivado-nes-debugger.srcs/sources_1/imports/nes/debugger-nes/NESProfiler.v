module NESProfiler(
    input i_clk,
    input i_reset_n,
    
    // Interface to Debugger
    output [15:0] o_sample_data,
    input [15:0] i_sample_index,
    input [15:0] i_sample_data_index,

    // Interface to NES
    input [31:0] i_sample_data,

    // Enable writes on the profiler
    input i_wen
);

localparam MAX_NUM_SAMPLES = 4096;          // NOTE: this is configured in ProfilerMemory IP

reg [12:0] r_sample_index;
reg [31:0] r_sample_data;
reg r_sample_write_enable;

// NES performs reads/writes at falling edge of clock
always @(negedge i_reset_n or negedge i_clk)
begin
    if (!i_reset_n)
    begin
        r_sample_index <= 0;
        r_sample_write_enable <= 0;
    end
    else
    begin
        r_sample_write_enable <= i_wen && (r_sample_index < (MAX_NUM_SAMPLES-1));

        if (r_sample_write_enable)
        begin
            if (r_sample_index < MAX_NUM_SAMPLES)
            begin
                r_sample_index <= r_sample_index + 1;            
            end
            
            r_sample_data <= i_sample_data;
        end        
    end
end

wire [31:0] w_sample_data_read;

// Memory performs reads/writes at rising edge of clock
NESProfilerMemory memory(
    // port A - write
    .clka(i_clk),
    .ena(1),
    .wea(r_sample_write_enable),
    .addra(r_sample_index[11:0]),
    .dina(r_sample_data),

    // port B - read
    .clkb(i_clk),
    .enb(1),      // input wire enb
    .addrb(i_sample_index[11:0]),
    .doutb(w_sample_data_read)
);

assign o_sample_data = (i_sample_data_index == 0) ? w_sample_data_read[15:0] : w_sample_data_read[31:16];

endmodule
