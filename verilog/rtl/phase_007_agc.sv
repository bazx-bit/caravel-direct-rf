// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_007_agc
// Description: Automatic Gain Control (AGC) & Fast-Attack Power Estimator
// Features: Fast-Attack / Slow-Decay Dual Loop, Instantaneous Power Estimator, 12-bit Gain Word, Inline SVA

`timescale 1ns / 1ps

module phase_007_agc #(
    parameter int INPUT_BITS = 16,
    parameter int GAIN_BITS  = 12,
    parameter int TARGET_PWR = 32'h08000000 // Target power threshold Q16.16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [INPUT_BITS-1:0] i_in,
    input  logic signed [INPUT_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic signed [INPUT_BITS-1:0] i_out,
    output logic signed [INPUT_BITS-1:0] q_out,
    output logic [GAIN_BITS-1:0]   gain_ctrl,
    output logic                   valid_out
);

    localparam int MAX_GAIN_VAL = (1 << GAIN_BITS) - 1; // 4095
    localparam int MIN_GAIN_VAL = 0;
    localparam int MID_GAIN_VAL = 1 << (GAIN_BITS - 1); // 2048

    // Internal Registers
    logic [GAIN_BITS-1:0] gain_reg;
    logic signed [31:0] inst_power;
    logic signed [31:0] power_est;

    // 1. Instantaneous Power Estimator: P = I^2 + Q^2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst_power <= '0;
            power_est  <= '0;
            gain_reg   <= MID_GAIN_VAL[GAIN_BITS-1:0];
            i_out      <= '0;
            q_out      <= '0;
            valid_out  <= 1'b0;
        end else if (valid_in) begin
            inst_power <= (i_in * i_in) + (q_in * q_in);

            // Dual-Loop Filter: Fast Attack vs Slow Decay
            if (inst_power > power_est) begin
                // Fast Attack (Alpha = 1/2)
                power_est <= power_est + ((inst_power - power_est) >>> 1);
            end else begin
                // Slow Decay (Alpha = 1/16)
                power_est <= power_est + ((inst_power - power_est) >>> 4);
            end

            // Gain Regulation
            if (power_est > TARGET_PWR) begin
                // Fast Gain Reduction
                if (gain_reg > (MIN_GAIN_VAL + 16))
                    gain_reg <= gain_reg - 16;
                else
                    gain_reg <= MIN_GAIN_VAL[GAIN_BITS-1:0];
            end else if (power_est < TARGET_PWR) begin
                // Slow Gain Increase
                if (gain_reg < (MAX_GAIN_VAL - 4))
                    gain_reg <= gain_reg + 4;
                else
                    gain_reg <= MAX_GAIN_VAL[GAIN_BITS-1:0];
            end

            // Apply Gain Multiplier to I and Q
            logic signed [31:0] i_scaled_full, q_scaled_full;
            i_scaled_full = (i_in * $signed({1'b0, gain_reg})) >>> 11;
            q_scaled_full = (q_in * $signed({1'b0, gain_reg})) >>> 11;

            // Output Saturation Clipping
            i_out <= i_scaled_full > 32767 ? 16'sd32767 : (i_scaled_full < -32768 ? -16'sd32768 : i_scaled_full[15:0]);
            q_out <= q_scaled_full > 32767 ? 16'sd32767 : (q_scaled_full < -32768 ? -16'sd32768 : q_scaled_full[15:0]);

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    assign gain_ctrl = gain_reg;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_agc_gain_bounds;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (gain_ctrl <= MAX_GAIN_VAL);
    endproperty
    assert_agc_gain_bounds: assert property (p_agc_gain_bounds);
    `endif

endmodule
