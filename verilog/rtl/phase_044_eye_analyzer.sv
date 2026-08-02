// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_044_eye_analyzer
// Description: Real-Time Eye Diagram & Signal Quality Analyzer Engine
// Features: EVM Accumulator, Signal Amplitude Range Estimator, Inline SVA

`timescale 1ns / 1ps

module phase_044_eye_analyzer #(
    parameter int DATA_BITS   = 16,
    parameter int WINDOW_LEN  = 1024
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Received Baseband Samples
    input  logic signed [DATA_BITS-1:0] rx_i_in,
    input  logic signed [DATA_BITS-1:0] rx_q_in,

    // Ideal Sliced Constellation Reference
    input  logic signed [DATA_BITS-1:0] ref_i_in,
    input  logic signed [DATA_BITS-1:0] ref_q_in,
    input  logic                   sample_valid_in,

    // Output Signal Quality Metrics
    output logic [31:0]            evm_error_acc_out,
    output logic [DATA_BITS-1:0]   eye_height_out,
    output logic [DATA_BITS-1:0]   eye_width_out,
    output logic                   metrics_valid_out
);

    logic [15:0] sample_cnt;
    logic [47:0] err_sq_acc;
    logic signed [DATA_BITS-1:0] max_amp, min_amp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt        <= '0;
            err_sq_acc        <= '0;
            max_amp           <= '0;
            min_amp           <= '0;
            evm_error_acc_out <= '0;
            eye_height_out    <= '0;
            eye_width_out     <= '0;
            metrics_valid_out <= 1'b0;
        end else if (sample_valid_in) begin
            logic signed [DATA_BITS-1:0] err_i, err_q;
            logic signed [31:0] inst_err_sq;

            err_i = rx_i_in - ref_i_in;
            err_q = rx_q_in - ref_q_in;
            inst_err_sq = err_i * err_i + err_q * err_q;

            // Track min/max amplitude
            if (rx_i_in > max_amp) max_amp <= rx_i_in;
            if (rx_i_in < min_amp) min_amp <= rx_i_in;

            if (sample_cnt == WINDOW_LEN - 1) begin
                sample_cnt        <= '0;
                evm_error_acc_out <= (err_sq_acc + inst_err_sq) >> 10; // Mean over 1024
                eye_height_out    <= max_amp - min_amp;
                eye_width_out     <= (max_amp - min_amp) >> 1;
                metrics_valid_out <= 1'b1;
                err_sq_acc        <= '0;
                max_amp           <= '0;
                min_amp           <= '0;
            end else begin
                sample_cnt        <= sample_cnt + 1'b1;
                err_sq_acc        <= err_sq_acc + inst_err_sq;
                metrics_valid_out <= 1'b0;
            end
        end else begin
            metrics_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_eye_valid_pulse;
        @(posedge clk) disable iff (!rst_n)
        metrics_valid_out |=> !metrics_valid_out;
    endproperty
    assert_eye_valid_pulse: assert property (p_eye_valid_pulse);
    `endif

endmodule
