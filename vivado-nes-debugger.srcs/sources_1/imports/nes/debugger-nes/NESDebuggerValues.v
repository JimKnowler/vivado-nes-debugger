/*
 * Write: VALUEID_CPU_STEP = 1, to trigger a single step of CPU
 * Read: VALUEID_CPU_STEP, ==1 while stepping, ==0 when finished stepping
 * Read: VALUDID_CPU_xxxx to read state of CPU
 */

module NESDebuggerValues(
    input i_clk,
    input i_reset_n,

    input i_ena,
    input i_wea,
    input [15:0] i_id,
    input [15:0] i_data,
    output [15:0] o_data,
    
    // profiler
    output o_profiler_wen,                          // enable the profiler to write to its' memory
    input [15:0] i_profiler_sample_data,
    output [15:0] o_profiler_sample_index,          // index of sample that profiler would like to view
    output [15:0] o_profiler_sample_data_index,     // index into data for current sample
    
    // NES reset_n signal
    output o_nes_reset_n,

    // memory pool selector for debugger memory access
    output [1:0] o_debugger_memory_pool
);

// Set the value of RESET_N pin on the NES
localparam VALUEID_NES_RESET_N = 1;

// Set the memory pool that the debugger accesses
// 0 = PRG, 1 = RAM, 2 = PATTERNTABLE (CHR), 3 = NAMETABLE
localparam VALUEID_DEBUGGER_MEMORY_POOL = 2;

// Set the current sample index that will be used when reading from the profiler
localparam VALUEID_PROFILER_SAMPLE_INDEX = 3;

// Set the index with the data of the current sample that will be used when reading from the profiler
localparam VALUEID_PROFILER_SAMPLE_DATA_INDEX = 4;

// Get data associated with the current sample index, and at the current sample data index
localparam VALUEID_PROFILER_SAMPLE_DATA = 5;

// Set write enable for profiler
localparam VALUEID_PROFILER_WEN = 6;

reg r_nes_reset_n;
reg [1:0] r_debugger_memory_pool;

reg [15:0] r_profiler_sample_index;
reg [15:0] r_profiler_sample_data_index;
reg r_profiler_wen;

reg [15:0] r_value;

// WRITE values
always @(posedge i_clk or negedge i_reset_n)
begin
    if (!i_reset_n)
    begin
        r_nes_reset_n <= 0;
        r_profiler_wen <= 0;
    end
    else
    begin                
        if (i_ena)
        begin
            if (i_wea)
            begin
                case (i_id)
                VALUEID_NES_RESET_N: begin
                    r_nes_reset_n <= (i_data == 1);
                end
                VALUEID_DEBUGGER_MEMORY_POOL: begin
                    r_debugger_memory_pool <= i_data[1:0];
                end
                VALUEID_PROFILER_SAMPLE_INDEX: begin
                    r_profiler_sample_index <= i_data;
                end
                VALUEID_PROFILER_SAMPLE_DATA_INDEX: begin
                    r_profiler_sample_data_index <= i_data;
                end
                VALUEID_PROFILER_WEN: begin
                    r_profiler_wen <= i_data;
                end
                default: begin
                end
                endcase
            end
        end
    end
end

// READ values
always @(*)
begin
    case (i_id)
    VALUEID_NES_RESET_N: begin
        r_value = { 15'd0, r_nes_reset_n };
    end
    VALUEID_DEBUGGER_MEMORY_POOL: begin
        r_value = { 14'd0, r_debugger_memory_pool };
    end
    VALUEID_PROFILER_SAMPLE_DATA: begin
        r_value = i_profiler_sample_data;
    end
    default:
        r_value = 0;
    endcase
end

assign o_data = i_ena ? r_value : 0;
assign o_nes_reset_n = r_nes_reset_n;
assign o_debugger_memory_pool = r_debugger_memory_pool;
assign o_profiler_sample_index = r_profiler_sample_index;
assign o_profiler_sample_data_index = r_profiler_sample_data_index;
assign o_profiler_wen = r_profiler_wen;

endmodule