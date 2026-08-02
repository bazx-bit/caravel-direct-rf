// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_019_dpd
// Description: Sub-Band Digital Pre-Distortion (DPD) Linearizer Engine
// Features: Volterra 3rd-Order Memory Polynomial Pre-Distorter, Out-of-Band ACPR Reduction, Inline SVA

`timescale 1ns / 1ps

module phase_019_dpd #(
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

    logic signed [DATA_BITS-1:0] prev_i, prev_q;

    // Polynomial Expansion & Multiplier Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_i    <= '0;
            prev_q    <= '0;
            i_out     <= '0;
            q_out     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Magnitude squared: |x|^2 = i^2 + q^2
            logic signed [31:0] mag_sq, mag_sq_prev;
            mag_sq      = (i_in * i_in + q_in * q_in) >>> 15;
            mag_sq_prev = (prev_i * prev_i + prev_q * prev_q) >>> 15;

            // 3rd-Order Volterra Term: x * |x|^2 * (-0.15)
            logic signed [31:0] term3_i, term3_q;
            term3_i = -((i_in * mag_sq) >>> 15) * 16'sd4915 >>> 15;
            term3_q = -((q_in * mag_sq) >>> 15) * 16'sd4915 >>> 15;

            // Memory Term: x_prev * |x_prev|^2 * (-0.05)
            logic signed [31:0] mem3_i, mem3_q;
            mem3_i = -((prev_i * mag_sq_prev) >>> 15) * 16'sd1638 >>> 15;
            mem3_q = -((prev_q * mag_sq_prev) >>> 15) * 16'sd1638 >>> 15;

            logic signed [31:0] dpd_i, dpd_q;
            dpd_i = $signed(i_in) + term3_i + mem3_i;
            dpd_q = $signed(q_in) + term3_q + mem3_q;

            i_out <= dpd_i > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (dpd_i < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : dpd_i[DATA_BITS-1:0]);
            q_out <= dpd_q > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (dpd_q < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : dpd_q[DATA_BITS-1:0]);

            prev_i    <= i_in;
            prev_q    <= q_in;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_dpd_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_dpd_valid_sync: assert property (p_dpd_valid_sync);
    `endif

endmodule
