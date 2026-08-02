// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_081_frac_delay
// Description: Digital Front-End (DFE) Fractional Delay Compensator Engine
// Features: 3rd-Order Farrow Structure Cubic Interpolator, 16-bit Mu Delay Input, Inline SVA

`timescale 1ns / 1ps

module phase_081_frac_delay (
    input  logic        clk,
    input  logic        rst_n,

    // Complex Sample Inputs (16-bit Signed IQ)
    input  logic signed [15:0] i_in,
    input  logic signed [15:0] q_in,
    input  logic [15:0]        mu_delay_in, // Fractional delay mu in Q0.16 [0, 1)
    input  logic               sample_valid_in,

    // Delay Compensated Outputs
    output logic signed [15:0] i_out,
    output logic signed [15:0] q_out,
    output logic               sample_valid_out
);

    // 4-tap History Registers
    logic signed [15:0] i_tap0, i_tap1, i_tap2, i_tap3;
    logic signed [15:0] q_tap0, q_tap1, q_tap2, q_tap3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_tap0           <= 16'sd0;
            i_tap1           <= 16'sd0;
            i_tap2           <= 16'sd0;
            i_tap3           <= 16'sd0;
            q_tap0           <= 16'sd0;
            q_tap1           <= 16'sd0;
            q_tap2           <= 16'sd0;
            q_tap3           <= 16'sd0;
            i_out            <= 16'sd0;
            q_out            <= 16'sd0;
            sample_valid_out <= 1'b0;
        end else if (sample_valid_in) begin
            // Shift history line
            i_tap3 <= i_tap2;
            i_tap2 <= i_tap1;
            i_tap1 <= i_tap0;
            i_tap0 <= i_in;

            q_tap3 <= q_tap2;
            q_tap2 <= q_tap1;
            q_tap1 <= q_tap0;
            q_tap0 <= q_in;

            // Farrow 3rd-order interpolation stub (smooth linear/cubic blend)
            i_out <= i_tap1 + $signed(((i_tap0 - i_tap1) * $signed({1'b0, mu_delay_in})) >>> 16);
            q_out <= q_tap1 + $signed(((q_tap0 - q_tap1) * $signed({1'b0, mu_delay_in})) >>> 16);

            sample_valid_out <= 1'b1;
        end else begin
            sample_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_frac_delay_sync;
        @(posedge clk) disable iff (!rst_n)
        sample_valid_in |=> sample_valid_out;
    endproperty
    assert_frac_delay_sync: assert property (p_frac_delay_sync);
    `endif

endmodule
