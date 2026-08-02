// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_047_embedded_logic_analyzer
// Description: On-Chip Embedded Logic Analyzer (ELA) & Real-Time Hardware Signal Trace Buffer Engine
// Features: Pattern Match Trigger, Circular Trace SRAM Buffer, Inline SVA

`timescale 1ns / 1ps

module phase_047_embedded_logic_analyzer #(
    parameter int PROBE_WIDTH  = 32,
    parameter int BUFFER_DEPTH = 1024
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Internal Signal Probes
    input  logic [PROBE_WIDTH-1:0] probe_data_in,
    input  logic                   probe_valid_in,

    // Trigger Setup Controls
    input  logic [PROBE_WIDTH-1:0] trigger_match_in,
    input  logic [PROBE_WIDTH-1:0] trigger_mask_in,
    input  logic                   arm_trigger_in,

    // Status & Readout Interface
    output logic                   trigger_fired_out,
    output logic [9:0]             write_pointer_out,
    output logic [PROBE_WIDTH-1:0] trace_data_out,
    output logic                   trace_valid_out
);

    // Circular Buffer Memory
    logic [PROBE_WIDTH-1:0] ram [0:BUFFER_DEPTH-1];
    logic [9:0] wr_ptr;
    logic       triggered;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr            <= '0;
            triggered         <= 1'b0;
            trigger_fired_out <= 1'b0;
            trace_data_out    <= '0;
            trace_valid_out   <= 1'b0;
            write_pointer_out <= '0;
        end else if (probe_valid_in) begin
            ram[wr_ptr]       <= probe_data_in;
            trace_data_out    <= probe_data_in;
            write_pointer_out <= wr_ptr;
            trace_valid_out   <= 1'b1;

            if (arm_trigger_in && !triggered) begin
                if ((probe_data_in & trigger_mask_in) == (trigger_match_in & trigger_mask_in)) begin
                    triggered         <= 1'b1;
                    trigger_fired_out <= 1'b1;
                end
            end

            wr_ptr <= wr_ptr + 1'b1;
        end else begin
            trace_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_ela_probe_sync;
        @(posedge clk) disable iff (!rst_n)
        probe_valid_in |=> trace_valid_out;
    endproperty
    assert_ela_probe_sync: assert property (p_ela_probe_sync);
    `endif

endmodule
