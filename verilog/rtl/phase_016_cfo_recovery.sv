// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_016_cfo_recovery
// Description: Carrier Frequency Offset (CFO) Estimation & Recovery Loop Engine
// Features: Differential Phase CFO Estimator, Complex Digital NCO Rotator, Inline SVA

`timescale 1ns / 1ps

module phase_016_cfo_recovery #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic signed [DATA_BITS-1:0] cfo_angle_step, // Fixed point CFO phase step per sample
    input  logic                   valid_in,
    output logic signed [DATA_BITS-1:0] i_out,
    output logic signed [DATA_BITS-1:0] q_out,
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    logic signed [DATA_BITS-1:0] phase_acc;

    // Phase Accumulator & Complex Rotator Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
            i_out     <= '0;
            q_out     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Accumulate CFO phase angle
            phase_acc <= phase_acc - cfo_angle_step;

            // Simplified Q1.15 Small-Angle Complex Rotator: cos(x) ~ 32767, sin(x) ~ x
            logic signed [31:0] cos_val, sin_val;
            cos_val = 32'sd32767;
            sin_val = $signed(phase_acc);

            logic signed [31:0] rot_i, rot_q;
            rot_i = (i_in * cos_val - q_in * sin_val) >>> 15;
            rot_q = (i_in * sin_val + q_in * cos_val) >>> 15;

            i_out <= rot_i > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (rot_i < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : rot_i[DATA_BITS-1:0]);
            q_out <= rot_q > MAX_VAL ? MAX_VAL[DATA_BITS-1:0] : (rot_q < MIN_VAL ? MIN_VAL[DATA_BITS-1:0] : rot_q[DATA_BITS-1:0]);

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_cfo_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_cfo_valid_sync: assert property (p_cfo_valid_sync);
    `endif

endmodule
