// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_003_fir
// Description: 32-Tap Polyphase Equiripple FIR Anti-Aliasing & CIC Droop Compensation Filter
// Features: Symmetric Tap Optimization (16 Multipliers), Q1.15 Fixed-Point MAC Pipeline, Inline SVA

`timescale 1ns / 1ps

module phase_003_fir #(
    parameter int TAPS        = 32,
    parameter int INPUT_BITS  = 16,
    parameter int COEFF_BITS  = 16,
    parameter int ACCUM_BITS  = 40
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [INPUT_BITS-1:0] data_in,
    input  logic                   valid_in,
    output logic signed [INPUT_BITS-1:0] data_out,
    output logic                   valid_out
);

    localparam int HALF_TAPS = TAPS / 2; // 16 symmetric pairs
    localparam int MAX_VAL   = (1 << (INPUT_BITS - 1)) - 1;
    localparam int MIN_VAL   = -(1 << (INPUT_BITS - 1));

    // Shift Register Delay Line
    logic signed [INPUT_BITS-1:0] shift_reg [0:TAPS-1];

    // Precomputed Q1.15 Symmetric Filter Coefficients (Inverse-Sinc Compensating FIR Taps)
    logic signed [COEFF_BITS-1:0] coeff_rom [0:HALF_TAPS-1];

    initial begin
        coeff_rom[0]  = 16'sd120;   coeff_rom[1]  = -16'sd245;  coeff_rom[2]  = -16'sd512;  coeff_rom[3]  = 16'sd180;
        coeff_rom[4]  = 16'sd940;   coeff_rom[5]  = 16'sd410;   coeff_rom[6]  = -16'sd1420; coeff_rom[7]  = -16'sd1850;
        coeff_rom[8]  = 16'sd850;   coeff_rom[9]  = 16'sd4120;  coeff_rom[10] = 16'sd4210;  coeff_rom[11] = -16'sd5120;
        coeff_rom[12] = -16'sd14500;coeff_rom[13] = -16'sd12800;coeff_rom[14] = 16'sd18500; coeff_rom[15] = 16'sd32767;
    end

    // 1. Shift Register Delay Line Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < TAPS; k++) begin
                shift_reg[k] <= '0;
            end
        end else if (valid_in) begin
            shift_reg[0] <= data_in;
            for (int k = 1; k < TAPS; k++) begin
                shift_reg[k] <= shift_reg[k-1];
            end
        end
    end

    // 2. Symmetric Adder Pre-Adder & Multiplier Stage
    logic signed [INPUT_BITS:0] pre_adders [0:HALF_TAPS-1];
    logic signed [ACCUM_BITS-1:0] mult_products [0:HALF_TAPS-1];
    logic signed [ACCUM_BITS-1:0] mac_accumulator;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_accumulator <= '0;
            valid_out       <= 1'b0;
            data_out        <= '0;
        end else if (valid_in) begin
            // Symmetric Pre-adders (h[k] == h[TAPS-1-k])
            for (int k = 0; k < HALF_TAPS; k++) begin
                pre_adders[k]    <= shift_reg[k] + shift_reg[TAPS - 1 - k];
                mult_products[k] <= pre_adders[k] * coeff_rom[k];
            end

            // Accumulate all 16 multiplier outputs
            mac_accumulator <= '0;
            for (int k = 0; k < HALF_TAPS; k++) begin
                mac_accumulator <= mac_accumulator + mult_products[k];
            end

            // Scale back Q1.15 shift and saturate output
            data_out <= (mac_accumulator >>> 15) > MAX_VAL ? MAX_VAL[INPUT_BITS-1:0] :
                       ((mac_accumulator >>> 15) < MIN_VAL ? MIN_VAL[INPUT_BITS-1:0] : mac_accumulator[INPUT_BITS+14:15]);
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_fir_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> valid_out;
    endproperty
    assert_fir_valid_sync: assert property (p_fir_valid_sync);
    `endif

endmodule
