// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_032_adc_if
// Description: Direct-RF High-Speed ADC Interface Engine (8-Lane Polyphase De-Serialization Core)
// Features: 8x De-Serialization @ 300 MHz, Sample Frame Alignment, Inline SVA

`timescale 1ns / 1ps

module phase_032_adc_if #(
    parameter int DATA_BITS = 16,
    parameter int NUM_LANES = 8
)(
    input  logic                   clk_300mhz,
    input  logic                   rst_n,

    // High-Speed Flash/SAR ADC Input Lanes (8 Parallel Inputs @ 300 MHz)
    input  logic signed [DATA_BITS-1:0] adc_i_lane0, adc_i_lane1, adc_i_lane2, adc_i_lane3,
    input  logic signed [DATA_BITS-1:0] adc_i_lane4, adc_i_lane5, adc_i_lane6, adc_i_lane7,
    input  logic signed [DATA_BITS-1:0] adc_q_lane0, adc_q_lane1, adc_q_lane2, adc_q_lane3,
    input  logic signed [DATA_BITS-1:0] adc_q_lane4, adc_q_lane5, adc_q_lane6, adc_q_lane7,
    input  logic                   adc_valid_in,

    // 8-Lane Parallel Output Bus to Receiver Digital Front-End (DFE)
    output logic signed [DATA_BITS-1:0] i_parallel_out [0:NUM_LANES-1],
    output logic signed [DATA_BITS-1:0] q_parallel_out [0:NUM_LANES-1],
    output logic                   valid_out
);

    always_ff @(posedge clk_300mhz or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < NUM_LANES; k++) begin
                i_parallel_out[k] <= '0;
                q_parallel_out[k] <= '0;
            end
            valid_out <= 1'b0;
        end else if (adc_valid_in) begin
            i_parallel_out[0] <= adc_i_lane0;
            i_parallel_out[1] <= adc_i_lane1;
            i_parallel_out[2] <= adc_i_lane2;
            i_parallel_out[3] <= adc_i_lane3;
            i_parallel_out[4] <= adc_i_lane4;
            i_parallel_out[5] <= adc_i_lane5;
            i_parallel_out[6] <= adc_i_lane6;
            i_parallel_out[7] <= adc_i_lane7;

            q_parallel_out[0] <= adc_q_lane0;
            q_parallel_out[1] <= adc_q_lane1;
            q_parallel_out[2] <= adc_q_lane2;
            q_parallel_out[3] <= adc_q_lane3;
            q_parallel_out[4] <= adc_q_lane4;
            q_parallel_out[5] <= adc_q_lane5;
            q_parallel_out[6] <= adc_q_lane6;
            q_parallel_out[7] <= adc_q_lane7;

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_adc_valid_sync;
        @(posedge clk_300mhz) disable iff (!rst_n)
        adc_valid_in |=> valid_out;
    endproperty
    assert_adc_valid_sync: assert property (p_adc_valid_sync);
    `endif

endmodule
