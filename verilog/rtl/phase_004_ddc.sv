// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_004_ddc
// Description: Top-Level Digital Down-Converter (DDC) Pipeline
// Features: NCO Integration, Dual Q1.15 Quadrature Mixers, Dual 5-Stage CIC Decimators, Dual 32-Tap FIR Equalizers

`timescale 1ns / 1ps

module phase_004_ddc #(
    parameter int ACCUM_BITS  = 32,
    parameter int INPUT_BITS  = 16,
    parameter int OUTPUT_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [ACCUM_BITS-1:0]  ftw,
    input  logic [ACCUM_BITS-1:0]  phase_offset,
    input  logic [5:0]             decim_rate, // R = 16
    input  logic signed [INPUT_BITS-1:0] rf_data_in,
    input  logic                   rf_valid_in,
    output logic signed [OUTPUT_BITS-1:0] i_out,
    output logic signed [OUTPUT_BITS-1:0] q_out,
    output logic                   valid_out
);

    // Local NCO Outputs
    logic signed [INPUT_BITS-1:0] i_nco, q_nco;
    logic nco_valid;

    // Instantiate Phase 001 DDS / NCO
    phase_001_dds #(
        .ACCUM_BITS(ACCUM_BITS),
        .LUT_BITS(14),
        .OUTPUT_BITS(INPUT_BITS)
    ) u_dds (
        .clk(clk),
        .rst_n(rst_n),
        .ftw(ftw),
        .phase_offset(phase_offset),
        .i_out(i_nco),
        .q_out(q_nco),
        .valid_out(nco_valid)
    );

    // Digital Quadrature Mixer Signals
    logic signed [31:0] mult_i_full, mult_q_full;
    logic signed [INPUT_BITS-1:0] i_mix, q_mix;
    logic mix_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_i_full <= '0;
            mult_q_full <= '0;
            i_mix       <= '0;
            q_mix       <= '0;
            mix_valid   <= 1'b0;
        end else if (rf_valid_in && nco_valid) begin
            mult_i_full <= rf_data_in * i_nco;
            mult_q_full <= rf_data_in * q_nco;

            // Q1.15 * Q1.15 -> Q1.15 right-shift
            i_mix     <= mult_i_full[30:15];
            q_mix     <= mult_q_full[30:15];
            mix_valid <= 1'b1;
        end else begin
            mix_valid <= 1'b0;
        end
    end

    // CIC Decimator Output Signals
    logic signed [INPUT_BITS-1:0] i_cic_out, q_cic_out;
    logic cic_valid_i, cic_valid_q;

    // Instantiate Phase 002 Dual CIC Decimators
    phase_002_cic #(
        .STAGES(5),
        .INPUT_BITS(INPUT_BITS),
        .ACCUM_BITS(46),
        .OUTPUT_BITS(OUTPUT_BITS),
        .SHIFT_BITS(20)
    ) u_cic_i (
        .clk(clk),
        .rst_n(rst_n),
        .decim_rate(decim_rate),
        .data_in(i_mix),
        .valid_in(mix_valid),
        .data_out(i_cic_out),
        .valid_out(cic_valid_i)
    );

    phase_002_cic #(
        .STAGES(5),
        .INPUT_BITS(INPUT_BITS),
        .ACCUM_BITS(46),
        .OUTPUT_BITS(OUTPUT_BITS),
        .SHIFT_BITS(20)
    ) u_cic_q (
        .clk(clk),
        .rst_n(rst_n),
        .decim_rate(decim_rate),
        .data_in(q_mix),
        .valid_in(mix_valid),
        .data_out(q_cic_out),
        .valid_out(cic_valid_q)
    );

    // Instantiate Phase 003 Dual Polyphase FIR Equalizers
    logic fir_valid_i, fir_valid_q;

    phase_003_fir #(
        .TAPS(32),
        .INPUT_BITS(INPUT_BITS),
        .COEFF_BITS(16)
    ) u_fir_i (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(i_cic_out),
        .valid_in(cic_valid_i),
        .data_out(i_out),
        .valid_out(fir_valid_i)
    );

    phase_003_fir #(
        .TAPS(32),
        .INPUT_BITS(INPUT_BITS),
        .COEFF_BITS(16)
    ) u_fir_q (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(q_cic_out),
        .valid_in(cic_valid_q),
        .data_out(q_out),
        .valid_out(fir_valid_q)
    );

    assign valid_out = fir_valid_i && fir_valid_q;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_ddc_valid_out_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (fir_valid_i == fir_valid_q);
    endproperty
    assert_ddc_valid_out_sync: assert property (p_ddc_valid_out_sync);
    `endif

endmodule
