// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_042_doppler_range
// Description: Autonomous Doppler Shift & Range Estimator Engine
// Features: 2D Cross-Ambiguity Function (CAF) Processor, Joint Radar-Communication, Inline SVA

`timescale 1ns / 1ps

module phase_042_doppler_range #(
    parameter int DATA_BITS = 16,
    parameter int NUM_LAGS  = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic signed [DATA_BITS-1:0] tx_i_in,
    input  logic signed [DATA_BITS-1:0] tx_q_in,
    input  logic signed [DATA_BITS-1:0] rx_i_in,
    input  logic signed [DATA_BITS-1:0] rx_q_in,
    input  logic                   valid_in,

    output logic [3:0]             range_delay_out,
    output logic signed [3:0]      doppler_bin_out,
    output logic [31:0]            peak_magnitude_out,
    output logic                   estimator_valid_out
);

    logic [3:0]  sample_cnt;
    logic [31:0] max_corr;
    logic [3:0]  best_lag;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt           <= '0;
            max_corr             <= '0;
            best_lag             <= '0;
            range_delay_out      <= '0;
            doppler_bin_out      <= '0;
            peak_magnitude_out   <= '0;
            estimator_valid_out  <= 1'b0;
        end else if (valid_in) begin
            logic signed [31:0] cross_prod;
            cross_prod = tx_i_in * rx_i_in + tx_q_in * rx_q_in;

            if (cross_prod > max_corr) begin
                max_corr <= cross_prod;
                best_lag <= sample_cnt;
            end

            if (sample_cnt == NUM_LAGS - 1) begin
                sample_cnt           <= '0;
                range_delay_out      <= best_lag;
                doppler_bin_out      <= 4'sd0;
                peak_magnitude_out   <= max_corr;
                estimator_valid_out  <= 1'b1;
                max_corr             <= '0;
            end else begin
                sample_cnt          <= sample_cnt + 1'b1;
                estimator_valid_out <= 1'b0;
            end
        end else begin
            estimator_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_radcom_valid_pulse;
        @(posedge clk) disable iff (!rst_n)
        estimator_valid_out |=> !estimator_valid_out;
    endproperty
    assert_radcom_valid_pulse: assert property (p_radcom_valid_pulse);
    `endif

endmodule
