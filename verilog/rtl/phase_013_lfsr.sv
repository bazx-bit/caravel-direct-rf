// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_013_lfsr
// Description: Pseudo-Random Noise (PRN) / Galois LFSR Framing & Scrambler Engine
// Features: 16-Bit Galois LFSR (G(x) = x^16 + x^14 + x^13 + x^11 + 1), Dual-Mode Scrambler/PRN, Inline SVA

`timescale 1ns / 1ps

module phase_013_lfsr #(
    parameter logic [15:0] INITIAL_SEED = 16'hACE1,
    parameter logic [15:0] POLY_MASK    = 16'hB400
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mode, // 0: Scrambler/Descrambler, 1: PRN Preamble Generator
    input  logic        data_in,
    input  logic        valid_in,
    output logic        data_out,
    output logic        prn_out,
    output logic        valid_out
);

    logic [15:0] lfsr_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg  <= INITIAL_SEED;
            data_out  <= 1'b0;
            prn_out   <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            logic lsb;
            lsb = lfsr_reg[0];

            if (lsb) begin
                lfsr_reg <= (lfsr_reg >> 1) ^ POLY_MASK;
            end else begin
                lfsr_reg <= (lfsr_reg >> 1);
            end

            prn_out   <= lsb;
            data_out  <= mode ? lsb : (data_in ^ lsb);
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_lfsr_non_zero;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (lfsr_reg != 16 me'h0000);
    endproperty
    assert_lfsr_non_zero: assert property (p_lfsr_non_zero);
    `endif

endmodule
