// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_039_zf_precoding
// Description: Multi-User Zero-Forcing (ZF) Spatial Precoding Matrix Core
// Features: 4x4 Spatial Matrix Precoding, Inter-User Interference Cancellation, Inline SVA

`timescale 1ns / 1ps

module phase_039_zf_precoding #(
    parameter int DATA_BITS = 16,
    parameter int NUM_USERS = 4,
    parameter int NUM_ANTS  = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // 4 User Payload Streams
    input  logic signed [DATA_BITS-1:0] user_i_in [0:NUM_USERS-1],
    input  logic signed [DATA_BITS-1:0] user_q_in [0:NUM_USERS-1],
    input  logic                   valid_in,

    // Channel Precoding Weights (Q1.15 W Matrix)
    input  logic signed [DATA_BITS-1:0] w_matrix_i [0:NUM_ANTS-1][0:NUM_USERS-1],
    input  logic signed [DATA_BITS-1:0] w_matrix_q [0:NUM_ANTS-1][0:NUM_USERS-1],

    // 4 Antenna Transmit Streams
    output logic signed [DATA_BITS-1:0] ant_i_out [0:NUM_ANTS-1],
    output logic signed [DATA_BITS-1:0] ant_q_out [0:NUM_ANTS-1],
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int a = 0; a < NUM_ANTS; a++) begin
                ant_i_out[a] <= '0;
                ant_q_out[a] <= '0;
            end
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Matrix multiplication s_a = sum_u (W_au * x_u)
            for (int a = 0; a < NUM_ANTS; a++) begin
                logic signed [31:0] sum_i, sum_q;
                sum_i = '0;
                sum_q = '0;

                for (int u = 0; u < NUM_USERS; u++) begin
                    sum_i = sum_i + ((w_matrix_i[a][u] * user_i_in[u] - w_matrix_q[a][u] * user_q_in[u]) >>> 15);
                    sum_q = sum_q + ((w_matrix_i[a][u] * user_q_in[u] + w_matrix_q[a][u] * user_i_in[u]) >>> 15);
                end

                ant_i_out[a] <= (sum_i > MAX_VAL) ? MAX_VAL[DATA_BITS-1:0] : ((sum_i < MIN_VAL) ? MIN_VAL[DATA_BITS-1:0] : sum_i[DATA_BITS-1:0]);
                ant_q_out[a] <= (sum_q > MAX_VAL) ? MAX_VAL[DATA_BITS-1:0] : ((sum_q < MIN_VAL) ? MIN_VAL[DATA_BITS-1:0] : sum_q[DATA_BITS-1:0]);
            end
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_zf_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_zf_valid_sync: assert property (p_zf_valid_sync);
    `endif

endmodule
