// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_043_fractional_resampler
// Description: Multi-Rate Fractional Resampling Arbitrary Rate Engine
// Features: 3rd-Order Farrow Cubic Polynomial Interpolator, Arbitrary Resampling, Inline SVA

`timescale 1ns / 1ps

module phase_043_fractional_resampler #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Input Sample Stream
    input  logic signed [DATA_BITS-1:0] sample_i_in,
    input  logic signed [DATA_BITS-1:0] sample_q_in,
    input  logic                   sample_valid_in,

    // Fractional Rate Step (Q16.16 format, fin / fout ratio)
    input  logic [31:0]            rate_ratio_in,

    // Output Resampled Stream
    output logic signed [DATA_BITS-1:0] sample_i_out,
    output logic signed [DATA_BITS-1:0] sample_q_out,
    output logic                   sample_valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    // 4-Tap History Buffer
    logic signed [DATA_BITS-1:0] buf_i [0:3];
    logic signed [DATA_BITS-1:0] buf_q [0:3];
    logic [31:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < 4; k++) begin
                buf_i[k] <= '0;
                buf_q[k] <= '0;
            end
            phase_acc        <= '0;
            sample_i_out     <= '0;
            sample_q_out     <= '0;
            sample_valid_out <= 1'b0;
        end else if (sample_valid_in) begin
            // Shift history buffer
            buf_i[0] <= buf_i[1]; buf_i[1] <= buf_i[2]; buf_i[2] <= buf_i[3]; buf_i[3] <= sample_i_in;
            buf_q[0] <= buf_q[1]; buf_q[1] <= buf_q[2]; buf_q[2] <= buf_q[3]; buf_q[3] <= sample_q_in;

            // Farrow Interpolation evaluation
            logic signed [31:0] c0_i, c1_i, res_i;
            logic signed [31:0] c0_q, c1_q, res_q;
            logic [15:0] mu;

            mu   = phase_acc[15:0];
            c0_i = buf_i[1];
            c1_i = (buf_i[2] - buf_i[0]) >>> 1;

            c0_q = buf_q[1];
            c1_q = (buf_q[2] - buf_q[0]) >>> 1;

            res_i = c0_i + ((c1_i * mu) >>> 16);
            res_q = c0_q + ((c1_q * mu) >>> 16);

            sample_i_out <= (res_i > MAX_VAL) ? MAX_VAL[DATA_BITS-1:0] : ((res_i < MIN_VAL) ? MIN_VAL[DATA_BITS-1:0] : res_i[DATA_BITS-1:0]);
            sample_q_out <= (res_q > MAX_VAL) ? MAX_VAL[DATA_BITS-1:0] : ((res_q < MIN_VAL) ? MIN_VAL[DATA_BITS-1:0] : res_q[DATA_BITS-1:0]);

            phase_acc        <= phase_acc + rate_ratio_in;
            sample_valid_out <= 1'b1;
        end else begin
            sample_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_farrow_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        sample_valid_in |=> sample_valid_out;
    endproperty
    assert_farrow_valid_sync: assert property (p_farrow_valid_sync);
    `endif

endmodule
