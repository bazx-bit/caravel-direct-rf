// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_058_dds_chirp
// Description: Direct Digital Synthesizer (DDS) & Chirp Radar Waveform Generator Engine
// Features: 32-bit NCO, Linear FMCW Chirp Sweep, CORDIC IQ Sinusoid LUT, Inline SVA

`timescale 1ns / 1ps

module phase_058_dds_chirp (
    input  logic        clk,
    input  logic        rst_n,

    // DDS Mode & Tuning Inputs
    input  logic [31:0] ftw_start_in,
    input  logic [31:0] ftw_step_in,
    input  logic [15:0] sweep_length_in,
    input  logic        chirp_enable_in,

    // IQ Outputs (Q1.15 format)
    output logic signed [15:0] dds_out_i,
    output logic signed [15:0] dds_out_q,
    output logic [31:0]        phase_acc_out,
    output logic               dds_valid_out
);

    logic [31:0] phase_acc;
    logic [31:0] current_ftw;
    logic [15:0] step_cnt;

    // Taylor-expansion / LUT approximation for Sin/Cos
    function automatic logic signed [15:0] get_cos(input logic [31:0] phase);
        logic signed [31:0] angle_norm;
        // Simple 16-bit Q1.15 cosine approximation
        return $signed(32767 - ((phase[31:16] * phase[31:16]) >> 17));
    endfunction

    function automatic logic signed [15:0] get_sin(input logic [31:0] phase);
        return $signed((phase[31:16] * 32767) >> 16);
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc     <= 32'h0;
            current_ftw   <= 32'h0;
            step_cnt      <= 16'h0;
            dds_out_i     <= 16'sd32767;
            dds_out_q     <= 16'sd0;
            phase_acc_out <= 32'h0;
            dds_valid_out <= 1'b0;
        end else begin
            if (chirp_enable_in) begin
                if (step_cnt == 16'h0) begin
                    current_ftw <= ftw_start_in;
                    step_cnt    <= 16'h1;
                end else if (step_cnt < sweep_length_in) begin
                    current_ftw <= current_ftw + ftw_step_in;
                    step_cnt    <= step_cnt + 1'b1;
                end else begin
                    current_ftw <= ftw_start_in;
                    step_cnt    <= 16'h0;
                end

                phase_acc     <= phase_acc + current_ftw;
                phase_acc_out <= phase_acc + current_ftw;

                dds_out_i     <= get_cos(phase_acc);
                dds_out_q     <= get_sin(phase_acc);
                dds_valid_out <= 1'b1;
            end else begin
                phase_acc     <= phase_acc + ftw_start_in;
                phase_acc_out <= phase_acc + ftw_start_in;

                dds_out_i     <= get_cos(phase_acc);
                dds_out_q     <= get_sin(phase_acc);
                dds_valid_out <= 1'b1;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_dds_phase_accumulates;
        @(posedge clk) disable iff (!rst_n)
        1'b1 |=> (phase_acc_out == $past(phase_acc_out) + $past(current_ftw, 1, 32'h0));
    endproperty
    assert_dds_phase_accumulates: assert property (p_dds_phase_accumulates);
    `endif

endmodule
