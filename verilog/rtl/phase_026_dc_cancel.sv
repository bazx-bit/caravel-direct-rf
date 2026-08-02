// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_026_dc_cancel
// Description: DC Offset Cancellation & Notch Filter Engine
// Features: High-Pass IIR Single-Pole Notch Filter, 0 Hz LO Leakage Suppression > 50 dB, Inline SVA

`timescale 1ns / 1ps

module phase_026_dc_cancel #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic signed [DATA_BITS-1:0] i_out,
    output logic signed [DATA_BITS-1:0] q_out,
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    // Alpha = 0.95 represented in Q1.15 (16'sd31130)
    localparam logic signed [15:0] ALPHA_Q15 = 16'sd31130;

    logic signed [DATA_BITS-1:0] prev_x_i, prev_x_q;
    logic signed [31:0]          prev_y_i, prev_y_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_x_i  <= '0;
            prev_x_q  <= '0;
            prev_y_i  <= '0;
            prev_y_q  <= '0;
            i_out     <= '0;
            q_out     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // y[n] = x[n] - x[n-1] + alpha * y[n-1]
            logic signed [31:0] diff_i, diff_q;
            logic signed [31:0] alpha_term_i, alpha_term_q;
            logic signed [31:0] y_i, y_q;

            diff_i = $signed(i_in) - $signed(prev_x_i);
            diff_q = $signed(q_in) - $signed(prev_x_q);

            alpha_term_i = (prev_y_i * ALPHA_Q15) >>> 15;
            alpha_term_q = (prev_y_q * ALPHA_Q15) >>> 15;

            y_i = diff_i + alpha_term_i;
            y_q = diff_q + alpha_term_q;

            prev_x_i <= i_in;
            prev_x_q <= q_in;
            prev_y_i <= y_i;
            prev_y_q <= y_q;

            i_out <= y_i > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (y_i < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : y_i[DATA_BITS-1:0]);
            q_out <= y_q > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (y_q < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : y_q[DATA_BITS-1:0]);

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_dc_cancel_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_dc_cancel_valid_sync: assert property (p_dc_cancel_valid_sync);
    `endif

endmodule
