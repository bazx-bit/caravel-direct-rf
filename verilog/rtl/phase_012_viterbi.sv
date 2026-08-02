// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_012_viterbi
// Description: Viterbi Convolutional Decoder Engine (K=7, Rate=1/2, Polynomials 171/133 Octal)
// Features: 64 Trellis States, ACS Parallel Units, 32-Depth Traceback Memory, Inline SVA

`timescale 1ns / 1ps

module phase_012_viterbi #(
    parameter int K_CONSTRAINT    = 7,
    parameter int NUM_STATES      = 64,
    parameter int TRACEBACK_DEPTH = 32
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [1:0]             rx_sym_in, // Received (out1, out2) 2-bit symbol
    input  logic                   valid_in,
    output logic                   decoded_bit_out,
    output logic                   valid_out
);

    // State Metric Registers for 64 Trellis States
    logic [15:0] state_metrics [0:NUM_STATES-1];
    logic [15:0] next_metrics  [0:NUM_STATES-1];
    logic [5:0]  tb_memory     [0:TRACEBACK_DEPTH-1][0:NUM_STATES-1];

    logic [4:0]  tb_ptr;

    // 1. Add-Compare-Select (ACS) Trellis Update Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_metrics[0] <= 16'd0;
            for (int k = 1; k < NUM_STATES; k++) begin
                state_metrics[k] <= 16'd10000;
            end
            tb_ptr    <= '0;
            valid_out <= 1'b0;
            decoded_bit_out <= 1'b0;
        end else if (valid_in) begin
            // Compute candidate Branch Metrics for 64 States
            for (int s = 0; s < NUM_STATES; s++) begin
                logic [5:0] prev_s0, prev_s1;
                logic [1:0] exp0, exp1;
                logic [15:0] bm0, bm1;
                logic [15:0] cand0, cand1;

                prev_s0 = {1'b0, s[5:1]};
                prev_s1 = {1'b1, s[5:1]};

                // Hamming distance computation
                bm0 = (rx_sym_in[1] ^ s[0]) + (rx_sym_in[0] ^ s[1]);
                bm1 = (rx_sym_in[1] ^ ~s[0]) + (rx_sym_in[0] ^ ~s[1]);

                cand0 = state_metrics[prev_s0] + bm0;
                cand1 = state_metrics[prev_s1] + bm1;

                if (cand0 <= cand1) begin
                    next_metrics[s]        <= cand0;
                    tb_memory[tb_ptr][s]   <= prev_s0;
                end else begin
                    next_metrics[s]        <= cand1;
                    tb_memory[tb_ptr][s]   <= prev_s1;
                end
            end

            for (int k = 0; k < NUM_STATES; k++) begin
                state_metrics[k] <= next_metrics[k];
            end

            // Traceback extraction
            logic [5:0] curr_st;
            curr_st = 6 me'd0;
            for (int t = 0; t < TRACEBACK_DEPTH; t++) begin
                curr_st = tb_memory[(tb_ptr - t) % TRACEBACK_DEPTH][curr_st];
            end

            decoded_bit_out <= curr_st[5];
            valid_out       <= 1'b1;
            tb_ptr          <= tb_ptr + 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_viterbi_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_viterbi_valid_sync: assert property (p_viterbi_valid_sync);
    `endif

endmodule
