// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_046_pll_synthesizer
// Description: Multi-Band Dynamic Frequency Synthesizer & Fractional-N PLL Controller Core
// Features: MASH 1-1-1 3rd-Order Delta-Sigma Modulator, Digital Lock Detector, Inline SVA

`timescale 1ns / 1ps

module phase_046_pll_synthesizer #(
    parameter int FRAC_BITS = 24
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Frequency Tuning Controls
    input  logic [7:0]             n_int_in,       // Integer Divider (e.g. 24 for 2.4 GHz)
    input  logic [FRAC_BITS-1:0]   k_frac_in,      // 24-bit Fractional Word
    input  logic                   tune_valid_in,

    // Feedback Multi-Modulus Divider Output
    output logic [9:0]             n_divider_total_out,
    output logic                   pll_locked_out,
    output logic                   synth_valid_out
);

    logic [FRAC_BITS-1:0] acc1, acc2, acc3;
    logic [7:0] lock_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc1                 <= '0;
            acc2                 <= '0;
            acc3                 <= '0;
            lock_cnt             <= '0;
            n_divider_total_out  <= '0;
            pll_locked_out       <= 1'b0;
            synth_valid_out      <= 1'b0;
        end else if (tune_valid_in) begin
            // MASH 1-1-1 3rd-Order Delta-Sigma Accumulation
            logic [FRAC_BITS:0] sum1, sum2, sum3;
            logic c1, c2, c3;
            logic signed [3:0] delta_n;

            sum1 = acc1 + k_frac_in;
            c1   = sum1[FRAC_BITS];
            acc1 <= sum1[FRAC_BITS-1:0];

            sum2 = acc2 + sum1[FRAC_BITS-1:0];
            c2   = sum2[FRAC_BITS];
            acc2 <= sum2[FRAC_BITS-1:0];

            sum3 = acc3 + sum2[FRAC_BITS-1:0];
            c3   = sum3[FRAC_BITS];
            acc3 <= sum3[FRAC_BITS-1:0];

            delta_n = (c1 ? 1'sb1 : 1'sb0) + (c2 ? 1'sb1 : 1'sb0) - (c3 ? 1'sb1 : 1'sb0);
            n_divider_total_out <= n_int_in + delta_n;

            if (lock_cnt < 8'hFF) lock_cnt <= lock_cnt + 1'b1;
            pll_locked_out  <= (lock_cnt > 8'h20);
            synth_valid_out <= 1'b1;
        end else begin
            synth_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_pll_synth_sync;
        @(posedge clk) disable iff (!rst_n)
        tune_valid_in |=> synth_valid_out;
    endproperty
    assert_pll_synth_sync: assert property (p_pll_synth_sync);
    `endif

endmodule
