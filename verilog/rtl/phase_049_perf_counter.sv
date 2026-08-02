// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_049_perf_counter
// Description: On-Chip Hardware Performance Counter & Profiler Engine
// Features: 8x 32-bit Event Counters, Global Cycle Counter, Saturation Logic, Inline SVA

`timescale 1ns / 1ps

module phase_049_perf_counter #(
    parameter int NUM_COUNTERS  = 8,
    parameter int COUNTER_BITS  = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // Event Inputs (one-hot bitmask of simultaneous events)
    input  logic [NUM_COUNTERS-1:0]     event_enables_in,
    input  logic                        event_valid_in,

    // Counter Readout Interface
    input  logic [2:0]                  read_counter_id_in,
    output logic [COUNTER_BITS-1:0]     counter_value_out,
    output logic [COUNTER_BITS-1:0]     cycle_count_out,
    output logic                        counter_valid_out
);

    // Event counter array and global cycle counter
    logic [COUNTER_BITS-1:0] counters [0:NUM_COUNTERS-1];
    logic [COUNTER_BITS-1:0] cycle_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt         <= '0;
            counter_valid_out <= 1'b0;
            counter_value_out <= '0;
            cycle_count_out   <= '0;
            for (int i = 0; i < NUM_COUNTERS; i++) begin
                counters[i] <= '0;
            end
        end else begin
            // Global cycle counter (saturating)
            if (cycle_cnt < {COUNTER_BITS{1'b1}})
                cycle_cnt <= cycle_cnt + 1'b1;

            // Event counting
            if (event_valid_in) begin
                for (int i = 0; i < NUM_COUNTERS; i++) begin
                    if (event_enables_in[i] && counters[i] < {COUNTER_BITS{1'b1}})
                        counters[i] <= counters[i] + 1'b1;
                end
            end

            // Readout
            counter_value_out <= counters[read_counter_id_in];
            cycle_count_out   <= cycle_cnt;
            counter_valid_out <= 1'b1;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_cycle_count_monotonic;
        @(posedge clk) disable iff (!rst_n)
        (cycle_cnt < {COUNTER_BITS{1'b1}}) |=> (cycle_cnt == $past(cycle_cnt) + 1);
    endproperty
    assert_cycle_monotonic: assert property (p_cycle_count_monotonic);

    property p_counter_valid_after_reset;
        @(posedge clk) disable iff (!rst_n)
        1 |=> counter_valid_out;
    endproperty
    assert_counter_valid: assert property (p_counter_valid_after_reset);
    `endif

endmodule
