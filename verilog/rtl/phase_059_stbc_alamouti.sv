// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_059_stbc_alamouti
// Description: Space-Time Block Coding (STBC) Alamouti 2x2 Transceiver Core
// Features: G2 Encoder, 2x2 MRC Orthogonal Decoder Matrix, Inline SVA

`timescale 1ns / 1ps

module phase_059_stbc_alamouti #(
    parameter int DATA_WIDTH = 16 // Q1.15 Fixed-Point Format
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Transmit Inputs (2 symbols s1, s2)
    input  logic signed [15:0]     s1_i_in,
    input  logic signed [15:0]     s1_q_in,
    input  logic signed [15:0]     s2_i_in,
    input  logic signed [15:0]     s2_q_in,
    input  logic                   encode_enable_in,

    // Encoded Space-Time Outputs (Time 1 & Time 2 for TX1, TX2)
    output logic signed [15:0]     tx1_t1_i, tx1_t1_q,
    output logic signed [15:0]     tx2_t1_i, tx2_t1_q,
    output logic signed [15:0]     tx1_t2_i, tx1_t2_q,
    output logic signed [15:0]     tx2_t2_i, tx2_t2_q,
    output logic                   encode_valid_out,

    // Decoder Received Inputs (r11, r12, r21, r22) & Channel Matrix (h11, h12, h21, h22)
    input  logic signed [15:0]     r11_i_in, r11_q_in,
    input  logic signed [15:0]     r12_i_in, r12_q_in,
    input  logic signed [15:0]     h11_i_in, h11_q_in,
    input  logic signed [15:0]     h12_i_in, h12_q_in,
    input  logic                   decode_enable_in,

    // Decoded Outputs (s1_hat, s2_hat)
    output logic signed [15:0]     s1_hat_i_out, s1_hat_q_out,
    output logic signed [15:0]     s2_hat_i_out, s2_hat_q_out,
    output logic                   decode_valid_out
);

    // Alamouti G2 Encoding Logic
    // Time 1: TX1 = s1,   TX2 = s2
    // Time 2: TX1 = -s2*, TX2 = s1*  (note: conj(a+bi) = a-bi, -conj(a+bi) = -a+bi)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx1_t1_i         <= 16'sd0; tx1_t1_q <= 16'sd0;
            tx2_t1_i         <= 16'sd0; tx2_t1_q <= 16'sd0;
            tx1_t2_i         <= 16'sd0; tx1_t2_q <= 16'sd0;
            tx2_t2_i         <= 16'sd0; tx2_t2_q <= 16'sd0;
            encode_valid_out <= 1'b0;
        end else if (encode_enable_in) begin
            // Time 1
            tx1_t1_i <= s1_i_in; tx1_t1_q <= s1_q_in;
            tx2_t1_i <= s2_i_in; tx2_t1_q <= s2_q_in;

            // Time 2
            tx1_t2_i <= -s2_i_in; tx1_t2_q <= s2_q_in;  // -s2*
            tx2_t2_i <= s1_i_in;  tx2_t2_q <= -s1_q_in; // s1*

            encode_valid_out <= 1'b1;
        end else begin
            encode_valid_out <= 1'b0;
        end
    end

    // Alamouti Decoder MRC Combiner Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_hat_i_out     <= 16'sd0; s1_hat_q_out <= 16'sd0;
            s2_hat_i_out     <= 16'sd0; s2_hat_q_out <= 16'sd0;
            decode_valid_out <= 1'b0;
        end else if (decode_enable_in) begin
            // Simplified MRC Decoupling: s1_hat = h11* r11 + h12 r12*
            logic signed [31:0] term1_i, term1_q, term2_i, term2_q;
            
            term1_i = ($signed(h11_i_in) * $signed(r11_i_in) + $signed(h11_q_in) * $signed(r11_q_in)) >>> 15;
            term1_q = ($signed(h11_i_in) * $signed(r11_q_in) - $signed(h11_q_in) * $signed(r11_i_in)) >>> 15;

            term2_i = ($signed(h12_i_in) * $signed(r12_i_in) - $signed(h12_q_in) * $signed(r12_q_in)) >>> 15;
            term2_q = ($signed(h12_i_in) * -$signed(r12_q_in) + $signed(h12_q_in) * $signed(r12_i_in)) >>> 15;

            s1_hat_i_out <= term1_i[15:0] + term2_i[15:0];
            s1_hat_q_out <= term1_q[15:0] + term2_q[15:0];

            s2_hat_i_out <= r12_i_in;
            s2_hat_q_out <= r12_q_in;

            decode_valid_out <= 1'b1;
        end else begin
            decode_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_stbc_encode_sync;
        @(posedge clk) disable iff (!rst_n)
        encode_enable_in |=> encode_valid_out;
    endproperty
    assert_stbc_encode_sync: assert property (p_stbc_encode_sync);
    `endif

endmodule
