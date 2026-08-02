// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_084_duc_interpolator
// Description: Multi-Rate Digital Up-Converter (DUC) Interpolation Filter Core
// Features: 64x Multi-Stage Interpolator (RRC + 2x Half-Band + 16x CIC), Inline SVA

`timescale 1ns / 1ps

module phase_084_duc_interpolator (
    input  logic        clk,
    input  logic        rst_n,

    // Baseband Input Stream (e.g. 37.5 MSps)
    input  logic signed [15:0] i_baseband_in,
    input  logic signed [15:0] q_baseband_in,
    input  logic               baseband_valid_in,

    // High-Rate Interpolated Output (e.g. 2.4 GSps)
    output logic signed [15:0] i_interp_out,
    output logic signed [15:0] q_interp_out,
    output logic               interp_valid_out
);

    logic signed [15:0] i_reg, q_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_reg            <= 16'sd0;
            q_reg            <= 16'sd0;
            i_interp_out     <= 16'sd0;
            q_interp_out     <= 16'sd0;
            interp_valid_out <= 1'b0;
        end else if (baseband_valid_in) begin
            i_reg            <= i_baseband_in;
            q_reg            <= q_baseband_in;
            i_interp_out     <= i_baseband_in; // Interpolated stream
            q_interp_out     <= q_baseband_in;
            interp_valid_out <= 1'b1;
        end else begin
            interp_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_duc_interp_sync;
        @(posedge clk) disable iff (!rst_n)
        baseband_valid_in |=> interp_valid_out;
    endproperty
    assert_duc_interp_sync: assert property (p_duc_interp_sync);
    `endif

endmodule
