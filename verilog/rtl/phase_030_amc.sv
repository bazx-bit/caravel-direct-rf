// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_030_amc
// Description: Adaptive Modulation & Coding (AMC) Link Adaptation Controller
// Features: Real-Time EVM & SNR Estimator, Dynamic BPSK to 64-QAM Modulation Switching, Inline SVA

`timescale 1ns / 1ps

module phase_030_amc #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] err_i,
    input  logic signed [DATA_BITS-1:0] err_q,
    input  logic                   valid_in,

    output logic [1:0]             mod_scheme_out, // 00=BPSK, 01=QPSK, 10=16-QAM, 11=64-QAM
    output logic                   scheme_updated
);

    logic [31:0] err_sq_acc;
    logic [5:0]  symbol_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_sq_acc     <= '0;
            symbol_cnt     <= '0;
            mod_scheme_out <= 2'b00; // Default BPSK
            scheme_updated <= 1'b0;
        end else if (valid_in) begin
            logic [31:0] err_i_sq, err_q_sq;
            err_i_sq = $signed(err_i) * $signed(err_i);
            err_q_sq = $signed(err_q) * $signed(err_q);

            if (symbol_cnt == 6'd63) begin
                logic [31:0] avg_err;
                avg_err = (err_sq_acc + err_i_sq + err_q_sq) >> 6;
                err_sq_acc <= '0;
                symbol_cnt <= '0;

                // Threshold comparator for AMC decision
                if (avg_err < 32'd10000) begin
                    mod_scheme_out <= 2'b11; // 64-QAM (Low EVM / High SNR)
                end else if (avg_err < 32'd50000) begin
                    mod_scheme_out <= 2'b10; // 16-QAM
                end else if (avg_err < 32'd200000) begin
                    mod_scheme_out <= 2'b01; // QPSK
                end else begin
                    mod_scheme_out <= 2'b00; // BPSK (High EVM / Low SNR)
                end

                scheme_updated <= 1'b1;
            end else begin
                err_sq_acc     <= err_sq_acc + err_i_sq + err_q_sq;
                symbol_cnt     <= symbol_cnt + 1'b1;
                scheme_updated <= 1'b0;
            end
        end else begin
            scheme_updated <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_amc_update_pulse;
        @(posedge clk) disable iff (!rst_n)
        scheme_updated |=> !scheme_updated;
    endproperty
    assert_amc_update_pulse: assert property (p_amc_update_pulse);
    `endif

endmodule
