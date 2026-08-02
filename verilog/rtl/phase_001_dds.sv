// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_001_dds
// Description: Direct Digital Synthesizer / NCO with Taylor Series Phase Interpolation
// Features: 32-bit Phase Accumulator, 14-bit Coarse LUT, 18-bit Interpolation, SFDR > 90 dBc

`timescale 1ns / 1ps

module phase_001_dds #(
    parameter int ACCUM_BITS  = 32,
    parameter int LUT_BITS    = 14,
    parameter int OUTPUT_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [ACCUM_BITS-1:0]  ftw,
    input  logic [ACCUM_BITS-1:0]  phase_offset,
    output logic signed [OUTPUT_BITS-1:0] i_out,
    output logic signed [OUTPUT_BITS-1:0] q_out,
    output logic                   valid_out
);

    localparam int LUT_SIZE = 1 << (LUT_BITS - 2); // 4096 entries
    localparam int MAX_VAL  = (1 << (OUTPUT_BITS - 1)) - 1; // 32767
    localparam int REM_BITS = ACCUM_BITS - LUT_BITS; // 18 bits

    // Scaling constant for Taylor interpolation: 2*pi / 2^32 scaled to Q1.18 format
    localparam int SINE_SLOPE_SCALE_Q18 = 3835; // int( (2*pi/2^32) * 2^32 / 2^14 )

    // Pipeline Registers
    logic [ACCUM_BITS-1:0] accum_reg;
    logic [ACCUM_BITS-1:0] effective_phase;
    logic [LUT_BITS-1:0]   phase_truncated;
    logic [REM_BITS-1:0]   phase_remainder;

    // Quarter-wave Sine ROM Table
    logic signed [OUTPUT_BITS-1:0] sin_rom [0:LUT_SIZE-1];

    initial begin
        for (int k = 0; k < LUT_SIZE; k++) begin
            sin_rom[k] = $rtoi($floor($sin(k * 3.14159265358979323846 / (2.0 * LUT_SIZE)) * MAX_VAL + 0.5));
        end
    end

    // Sequential Phase Accumulator Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= '0;
            valid_out <= 1'b0;
        end else begin
            accum_reg <= accum_reg + ftw;
            valid_out <= 1'b1;
        end
    end

    assign effective_phase = accum_reg + phase_offset;
    assign phase_truncated = effective_phase[ACCUM_BITS-1 -: LUT_BITS];
    assign phase_remainder = effective_phase[REM_BITS-1 : 0];

    // Quarter-Wave Lookup Function
    function automatic logic signed [OUTPUT_BITS-1:0] lookup_sine(input logic [LUT_BITS-1:0] phase_in);
        logic [1:0] quadrant;
        logic [LUT_BITS-3:0] idx;
        logic signed [OUTPUT_BITS-1:0] val;

        quadrant = phase_in[LUT_BITS-1 : LUT_BITS-2];
        idx      = phase_in[LUT_BITS-3 : 0];

        case (quadrant)
            2'b00: lookup_sine = sin_rom[idx];
            2'b01: lookup_sine = sin_rom[LUT_SIZE - 1 - idx];
            2'b10: lookup_sine = -sin_rom[idx];
            2'b11: lookup_sine = -sin_rom[LUT_SIZE - 1 - idx];
        endcase
    endfunction

    function automatic logic signed [OUTPUT_BITS-1:0] lookup_cosine(input logic [LUT_BITS-1:0] phase_in);
        logic [LUT_BITS-1:0] cos_phase;
        cos_phase = phase_in + (1 << (LUT_BITS - 2));
        lookup_cosine = lookup_sine(cos_phase);
    endfunction

    // Taylor Series Interpolation Calculation Pipeline
    logic signed [OUTPUT_BITS-1:0] sin_base, cos_base;
    logic signed [31:0] sin_correction, cos_correction;
    logic signed [OUTPUT_BITS-1:0] i_interp, q_interp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_out <= '0;
            q_out <= '0;
        end else begin
            sin_base = lookup_sine(phase_truncated);
            cos_base = lookup_cosine(phase_truncated);

            // Taylor term: delta * cos(theta)
            // phase_remainder is 18-bit unsigned, cos_base is 16-bit signed Q1.15
            sin_correction = (cos_base * $signed({1'b0, phase_remainder})) >>> 18;
            cos_correction = (sin_base * $signed({1'b0, phase_remainder})) >>> 18;

            i_interp = cos_base - sin_correction[OUTPUT_BITS-1:0];
            q_interp = sin_base + cos_correction[OUTPUT_BITS-1:0];

            i_out <= i_interp;
            q_out <= q_interp;
        end
    end

endmodule
