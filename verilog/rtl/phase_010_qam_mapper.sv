// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_010_qam_mapper
// Description: Configurable QAM Symbol Mapper (BPSK / QPSK / 16-QAM / 64-QAM)
// Features: Gray Code Mapping, Normalized Q1.15 Fixed-Point Levels, Inline SVA Assertions

`timescale 1ns / 1ps

module phase_010_qam_mapper #(
    parameter int OUTPUT_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [1:0]             mod_type, // 00: BPSK, 01: QPSK, 10: 16-QAM, 11: 64-QAM
    input  logic [5:0]             bits_in,   // Bit payload (up to 6 bits/symbol)
    input  logic                   valid_in,
    output logic signed [OUTPUT_BITS-1:0] i_out,
    output logic signed [OUTPUT_BITS-1:0] q_out,
    output logic                   valid_out
);

    // Q1.15 Constellation Multi-Level Definitions
    localparam logic signed [15:0] BPSK_VAL  = 16'sd32767;
    localparam logic signed [15:0] QPSK_VAL  = 16'sd23170;
    localparam logic signed [15:0] QAM16_L1  = 16'sd10362;
    localparam logic signed [15:0] QAM16_L3  = 16'sd31086;
    localparam logic signed [15:0] QAM64_L0  = 16'sd4681;
    localparam logic signed [15:0] QAM64_L1  = 16'sd14043;
    localparam logic signed [15:0] QAM64_L2  = 16'sd23405;
    localparam logic signed [15:0] QAM64_L3  = 16'sd32767;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_out     <= '0;
            q_out     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            case (mod_type)
                2'b00: begin
                    // BPSK (1 bit)
                    i_out <= bits_in[0] ? BPSK_VAL : -BPSK_VAL;
                    q_out <= 16'sd0;
                end

                2'b01: begin
                    // QPSK (2 bits)
                    i_out <= bits_in[1] ? QPSK_VAL : -QPSK_VAL;
                    q_out <= bits_in[0] ? QPSK_VAL : -QPSK_VAL;
                end

                2'b10: begin
                    // 16-QAM (4 bits: Gray coded)
                    case (bits_in[3:2])
                        2'b11: i_out <= QAM16_L3;
                        2'b10: i_out <= QAM16_L1;
                        2'b01: i_out <= -QAM16_L1;
                        2'b00: i_out <= -QAM16_L3;
                    endcase

                    case (bits_in[1:0])
                        2'b11: q_out <= QAM16_L3;
                        2'b10: q_out <= QAM16_L1;
                        2'b01: q_out <= -QAM16_L1;
                        2'b00: q_out <= -QAM16_L3;
                    endcase
                end

                2'b11: begin
                    // 64-QAM (6 bits: 3 bits I, 3 bits Q)
                    case (bits_in[4:3])
                        2'b00: i_out <= bits_in[5] ? QAM64_L0 : -QAM64_L0;
                        2'b01: i_out <= bits_in[5] ? QAM64_L1 : -QAM64_L1;
                        2'b10: i_out <= bits_in[5] ? QAM64_L2 : -QAM64_L2;
                        2'b11: i_out <= bits_in[5] ? QAM64_L3 : -QAM64_L3;
                    endcase

                    case (bits_in[1:0])
                        2'b00: q_out <= bits_in[2] ? QAM64_L0 : -QAM64_L0;
                        2'b01: q_out <= bits_in[2] ? QAM64_L1 : -QAM64_L1;
                        2'b10: q_out <= bits_in[2] ? QAM64_L2 : -QAM64_L2;
                        2'b11: q_out <= bits_in[2] ? QAM64_L3 : -QAM64_L3;
                    endcase
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
    property p_qam_mod_bounds;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (mod_type <= 2'b11);
    endproperty
    assert_qam_mod_bounds: assert property (p_qam_mod_bounds);
    `endif

endmodule
