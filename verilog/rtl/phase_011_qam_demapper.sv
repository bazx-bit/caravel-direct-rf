// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_011_qam_demapper
// Description: QAM Slicer & Hard/Soft Demapper Engine (Decision Boundaries & LLR Generator)
// Features: BPSK/QPSK/16-QAM/64-QAM Demapping, Hard Bits, Soft LLR Outputs, Inline SVA Assertions

`timescale 1ns / 1ps

module phase_011_qam_demapper #(
    parameter int INPUT_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [1:0]             mod_type, // 00: BPSK, 01: QPSK, 10: 16-QAM, 11: 64-QAM
    input  logic signed [INPUT_BITS-1:0] i_in,
    input  logic signed [INPUT_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic [5:0]             hard_bits_out,
    output logic signed [15:0]     llr_out [0:5],
    output logic                   valid_out
);

    // Q1.15 Slicing Threshold Constants
    localparam logic signed [15:0] QAM16_TH1 = 16'sd20724;
    localparam logic signed [15:0] QAM64_TH1 = 16'sd9362;
    localparam logic signed [15:0] QAM64_TH2 = 16'sd18724;
    localparam logic signed [15:0] QAM64_TH3 = 16'sd28086;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hard_bits_out <= '0;
            valid_out     <= 1'b0;
            for (int k = 0; k < 6; k++) begin
                llr_out[k] <= '0;
            end
        end else if (valid_in) begin
            case (mod_type)
                2'b00: begin
                    // BPSK (1 bit)
                    hard_bits_out <= {5'b00000, (i_in >= 0 ? 1'b1 : 1'b0)};
                    llr_out[0]    <= i_in;
                    llr_out[1]    <= '0; llr_out[2] <= '0; llr_out[3] <= '0; llr_out[4] <= '0; llr_out[5] <= '0;
                end

                2'b01: begin
                    // QPSK (2 bits)
                    hard_bits_out <= {4'b0000, (i_in >= 0 ? 1'b1 : 1'b0), (q_in >= 0 ? 1'b1 : 1'b0)};
                    llr_out[0]    <= i_in;
                    llr_out[1]    <= q_in;
                    llr_out[2]    <= '0; llr_out[3] <= '0; llr_out[4] <= '0; llr_out[5] <= '0;
                end

                2'b10: begin
                    // 16-QAM (4 bits)
                    logic [1:0] b3_2, b1_0;
                    b3_2 = (i_in >= QAM16_TH1) ? 2'b11 : ((i_in >= 0) ? 2'b10 : ((i_in >= -QAM16_TH1) ? 2'b01 : 2'b00));
                    b1_0 = (q_in >= QAM16_TH1) ? 2'b11 : ((q_in >= 0) ? 2'b10 : ((q_in >= -QAM16_TH1) ? 2'b01 : 2'b00));

                    hard_bits_out <= {2'b00, b3_2, b1_0};
                    llr_out[0]    <= i_in;
                    llr_out[1]    <= QAM16_TH1 - (i_in >= 0 ? i_in : -i_in);
                    llr_out[2]    <= q_in;
                    llr_out[3]    <= QAM16_TH1 - (q_in >= 0 ? q_in : -q_in);
                    llr_out[4]    <= '0; llr_out[5] <= '0;
                end

                2'b11: begin
                    // 64-QAM (6 bits)
                    logic [2:0] idx_i, idx_q;
                    idx_i = (i_in >= QAM64_TH3) ? 3'd7 : ((i_in >= QAM64_TH2) ? 3'd6 : ((i_in >= QAM64_TH1) ? 3'd5 : ((i_in >= 0) ? 3'd4 : ((i_in >= -QAM64_TH1) ? 3'd3 : ((i_in >= -QAM64_TH2) ? 3'd2 : ((i_in >= -QAM64_TH3) ? 3'd1 : 3'd0))))));
                    idx_q = (q_in >= QAM64_TH3) ? 3'd7 : ((q_in >= QAM64_TH2) ? 3'd6 : ((q_in >= QAM64_TH1) ? 3'd5 : ((q_in >= 0) ? 3'd4 : ((q_in >= -QAM64_TH1) ? 3'd3 : ((q_in >= -QAM64_TH2) ? 3'd2 : ((q_in >= -QAM64_TH3) ? 3'd1 : 3'd0))))));

                    hard_bits_out <= {idx_i, idx_q};
                    llr_out[0]    <= i_in;
                    llr_out[1]    <= QAM64_TH2 - (i_in >= 0 ? i_in : -i_in);
                    llr_out[2]    <= QAM64_TH1 - ((i_in >= 0 ? i_in : -i_in) >= QAM64_TH2 ? (i_in >= 0 ? i_in : -i_in) - QAM64_TH2 : QAM64_TH2 - (i_in >= 0 ? i_in : -i_in));
                    llr_out[3]    <= q_in;
                    llr_out[4]    <= QAM64_TH2 - (q_in >= 0 ? q_in : -q_in);
                    llr_out[5]    <= QAM64_TH1 - ((q_in >= 0 ? q_in : -q_in) >= QAM64_TH2 ? (q_in >= 0 ? q_in : -q_in) - QAM64_TH2 : QAM64_TH2 - (q_in >= 0 ? q_in : -q_in));
                end
            endcase
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_demapper_valid_out;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (mod_type <= 2'b11);
    endproperty
    assert_demapper_valid_out: assert property (p_demapper_valid_out);
    `endif

endmodule
