// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_015_preamble_sync
// Description: Digital Preamble Synchronizer & Cross-Correlator Engine
// Features: 16-Tap Sliding Window Cross-Correlator, Energy Threshold Peak Detector, Frame Sync Strobe, Inline SVA

`timescale 1ns / 1ps

module phase_015_preamble_sync #(
    parameter int TAP_COUNT  = 16,
    parameter int DATA_BITS  = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic signed [31:0]     corr_energy_out,
    output logic                   frame_sync_out,
    output logic                   valid_out
);

    // Reference PRN Preamble (+1 / -1 mapped array)
    localparam logic signed [DATA_BITS-1:0] REF_PREAMBLE [0:TAP_COUNT-1] = '{
        16'sd1, -16'sd1, 16'sd1, 16'sd1, -16'sd1, -16'sd1, 16'sd1, -16'sd1,
        16'sd1, 16'sd1, 16'sd1, -16'sd1, -16'sd1, 16'sd1, -16'sd1, 16'sd1
    };

    localparam logic signed [31:0] THRESHOLD_LIMIT = 32'sd360000;

    // Sliding Window Shift Registers
    logic signed [DATA_BITS-1:0] win_i [0:TAP_COUNT-1];
    logic signed [DATA_BITS-1:0] win_q [0:TAP_COUNT-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < TAP_COUNT; k++) begin
                win_i[k] <= '0;
                win_q[k] <= '0;
            end
            corr_energy_out <= '0;
            frame_sync_out  <= 1'b0;
            valid_out       <= 1'b0;
        end else if (valid_in) begin
            // Shift in new sample
            for (int k = TAP_COUNT-1; k > 0; k--) begin
                win_i[k] <= win_i[k-1];
                win_q[k] <= win_q[k-1];
            end
            win_i[0] <= i_in;
            win_q[0] <= q_in;

            // Parallel Cross-Correlation Dot Product
            logic signed [31:0] acc_i, acc_q;
            acc_i = '0;
            acc_q = '0;

            for (int k = 0; k < TAP_COUNT; k++) begin
                acc_i = acc_i + (win_i[k] * REF_PREAMBLE[k]);
                acc_q = acc_q + (win_q[k] * REF_PREAMBLE[k]);
            end

            logic signed [31:0] total_energy;
            total_energy = (acc_i >= 0 ? acc_i : -acc_i) + (acc_q >= 0 ? acc_q : -acc_q);

            corr_energy_out <= total_energy;
            frame_sync_out  <= (total_energy >= THRESHOLD_LIMIT) ? 1'b1 : 1'b0;
            valid_out       <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_sync_strobe_valid;
        @(posedge clk) disable iff (!rst_n)
        frame_sync_out |-> valid_out;
    endproperty
    assert_sync_strobe_valid: assert property (p_sync_strobe_valid);
    `endif

endmodule
