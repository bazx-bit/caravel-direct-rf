// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_033_beamforming
// Description: Multi-Channel Phased Array Digital Beamforming Phase Shifter Core
// Features: 4-Element Phased Array Steering, Coherent Array Summing, Inline SVA

`timescale 1ns / 1ps

module phase_033_beamforming #(
    parameter int DATA_BITS = 16,
    parameter int NUM_ELEMENTS = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // 4-Channel Antenna Array IQ Inputs
    input  logic signed [DATA_BITS-1:0] i_ch0_in, i_ch1_in, i_ch2_in, i_ch3_in,
    input  logic signed [DATA_BITS-1:0] q_ch0_in, q_ch1_in, q_ch2_in, q_ch3_in,
    input  logic                   valid_in,

    // Steering Phase Shift Coefficients (Q1.15 Cosine / Sine values)
    input  logic signed [15:0]     cos_phase0, sin_phase0,
    input  logic signed [15:0]     cos_phase1, sin_phase1,
    input  logic signed [15:0]     cos_phase2, sin_phase2,
    input  logic signed [15:0]     cos_phase3, sin_phase3,

    // Formed Single-Beam Output Stream
    output logic signed [DATA_BITS-1:0] i_beam_out,
    output logic signed [DATA_BITS-1:0] q_beam_out,
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_beam_out <= '0;
            q_beam_out <= '0;
            valid_out  <= 1'b0;
        end else if (valid_in) begin
            // Complex Multiplication: (I + jQ) * (cos + j sin) = (I*cos - Q*sin) + j(I*sin + Q*cos)
            logic signed [31:0] rot_i0, rot_q0, rot_i1, rot_q1;
            logic signed [31:0] rot_i2, rot_q2, rot_i3, rot_q3;
            logic signed [31:0] sum_i, sum_q;

            rot_i0 = (i_ch0_in * cos_phase0 - q_ch0_in * sin_phase0) >>> 15;
            rot_q0 = (i_ch0_in * sin_phase0 + q_ch0_in * cos_phase0) >>> 15;

            rot_i1 = (i_ch1_in * cos_phase1 - q_ch1_in * sin_phase1) >>> 15;
            rot_q1 = (i_ch1_in * sin_phase1 + q_ch1_in * cos_phase1) >>> 15;

            rot_i2 = (i_ch2_in * cos_phase2 - q_ch2_in * sin_phase2) >>> 15;
            rot_q2 = (i_ch2_in * sin_phase2 + q_ch2_in * cos_phase2) >>> 15;

            rot_i3 = (i_ch3_in * cos_phase3 - q_ch3_in * sin_phase3) >>> 15;
            rot_q3 = (i_ch3_in * sin_phase3 + q_ch3_in * cos_phase3) >>> 15;

            sum_i = (rot_i0 + rot_i1 + rot_i2 + rot_i3) >>> 2;
            sum_q = (rot_q0 + rot_q1 + rot_q2 + rot_q3) >>> 2;

            i_beam_out <= sum_i > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (sum_i < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : sum_i[DATA_BITS-1:0]);
            q_beam_out <= sum_q > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (sum_q < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : sum_q[DATA_BITS-1:0]);

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_beamforming_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_beamforming_valid_sync: assert property (p_beamforming_valid_sync);
    `endif

endmodule
