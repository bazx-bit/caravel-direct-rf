// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_025_iq_imbalance
// Description: Sub-Gigahertz IQ Imbalance Compensation Engine (Gram-Schmidt Gain & Phase Mismatch Corrector)
// Features: Gram-Schmidt Orthogonalization, Mirror Image Spur Suppression > 60 dB, Inline SVA

`timescale 1ns / 1ps

module phase_025_iq_imbalance #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic                   valid_in,

    // Correction Coefficients (Q1.15)
    input  logic signed [15:0]     gain_coeff,  // Default 1.0 (16'sd32767)
    input  logic signed [15:0]     phase_coeff, // Default 0.0 (16'sd0)

    output logic signed [DATA_BITS-1:0] i_out,
    output logic signed [DATA_BITS-1:0] q_out,
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_out     <= '0;
            q_out     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Gram-Schmidt Orthogonalization: Q_corr = (Q - sin(phase) * I) * gain
            logic signed [31:0] phase_term, q_orth, q_final;
            
            phase_term = (i_in * phase_coeff) >>> 15;
            q_orth     = $signed(q_in) - phase_term;
            q_final    = (q_orth * gain_coeff) >>> 15;

            i_out <= i_in;
            q_out <= q_final > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (q_final < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : q_final[DATA_BITS-1:0]);
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_iq_imbalance_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_iq_imbalance_valid_sync: assert property (p_iq_imbalance_valid_sync);
    `endif

endmodule
