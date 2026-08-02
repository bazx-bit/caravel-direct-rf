// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_040_spectrum_sensing
// Description: Autonomous Multi-Band Cognitive Spectrum Sensing Engine
// Features: Energy Detector, CFAR Threshold Comparator, Spectrum Occupancy Flag, Inline SVA

`timescale 1ns / 1ps

module phase_040_spectrum_sensing #(
    parameter int DATA_BITS  = 16,
    parameter int WINDOW_LEN = 256
)(
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic signed [DATA_BITS-1:0] sample_i_in,
    input  logic signed [DATA_BITS-1:0] sample_q_in,
    input  logic                   sample_valid_in,

    input  logic [31:0]            cfar_threshold_in,

    output logic [31:0]            accumulated_energy_out,
    output logic                   channel_occupied_out,
    output logic                   energy_valid_out
);

    logic [7:0]  win_cnt;
    logic [47:0] energy_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_cnt                <= '0;
            energy_acc             <= '0;
            accumulated_energy_out <= '0;
            channel_occupied_out   <= 1'b0;
            energy_valid_out       <= 1'b0;
        end else if (sample_valid_in) begin
            logic signed [31:0] inst_power;
            inst_power = sample_i_in * sample_i_in + sample_q_in * sample_q_in;

            if (win_cnt == WINDOW_LEN - 1) begin
                win_cnt                <= '0;
                accumulated_energy_out <= (energy_acc + inst_power) >> 8; // Mean division by 256
                channel_occupied_out   <= ((energy_acc + inst_power) >> 8) > cfar_threshold_in;
                energy_valid_out       <= 1'b1;
                energy_acc             <= '0;
            end else begin
                win_cnt          <= win_cnt + 1'b1;
                energy_acc       <= energy_acc + inst_power;
                energy_valid_out <= 1'b0;
            end
        end else begin
            energy_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_sensing_valid_pulse;
        @(posedge clk) disable iff (!rst_n)
        energy_valid_out |=> !energy_valid_out;
    endproperty
    assert_sensing_valid_pulse: assert property (p_sensing_valid_pulse);
    `endif

endmodule
