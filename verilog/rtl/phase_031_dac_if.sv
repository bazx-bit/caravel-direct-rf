// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_031_dac_if
// Description: Direct-RF High-Speed DAC Interface Engine (8-Lane Polyphase Parallel 2.4 GSps Transmit Core)
// Features: 8x Parallelization @ 300 MHz, Multi-Phase DAC Clock Alignment, Inline SVA

`timescale 1ns / 1ps

module phase_031_dac_if #(
    parameter int DATA_BITS = 16,
    parameter int NUM_LANES = 8
)(
    input  logic                   clk_300mhz,
    input  logic                   rst_n,

    // 8-Lane Parallel Input Bus @ 300 MHz
    input  logic signed [DATA_BITS-1:0] i_parallel_in [0:NUM_LANES-1],
    input  logic signed [DATA_BITS-1:0] q_parallel_in [0:NUM_LANES-1],
    input  logic                   valid_in,

    // High-Speed Current-Steering DAC Core Signals
    output logic signed [DATA_BITS-1:0] i_lane0_out, i_lane1_out, i_lane2_out, i_lane3_out,
    output logic signed [DATA_BITS-1:0] i_lane4_out, i_lane5_out, i_lane6_out, i_lane7_out,
    output logic signed [DATA_BITS-1:0] q_lane0_out, q_lane1_out, q_lane2_out, q_lane3_out,
    output logic signed [DATA_BITS-1:0] q_lane4_out, q_lane5_out, q_lane6_out, q_lane7_out,
    output logic                   dac_sync_out
);

    always_ff @(posedge clk_300mhz or negedge rst_n) begin
        if (!rst_n) begin
            i_lane0_out  <= '0; i_lane1_out  <= '0; i_lane2_out  <= '0; i_lane3_out  <= '0;
            i_lane4_out  <= '0; i_lane5_out  <= '0; i_lane6_out  <= '0; i_lane7_out  <= '0;
            q_lane0_out  <= '0; q_lane1_out  <= '0; q_lane2_out  <= '0; q_lane3_out  <= '0;
            q_lane4_out  <= '0; q_lane5_out  <= '0; q_lane6_out  <= '0; q_lane7_out  <= '0;
            dac_sync_out <= 1'b0;
        end else if (valid_in) begin
            i_lane0_out  <= i_parallel_in[0];
            i_lane1_out  <= i_parallel_in[1];
            i_lane2_out  <= i_parallel_in[2];
            i_lane3_out  <= i_parallel_in[3];
            i_lane4_out  <= i_parallel_in[4];
            i_lane5_out  <= i_parallel_in[5];
            i_lane6_out  <= i_parallel_in[6];
            i_lane7_out  <= i_parallel_in[7];

            q_lane0_out  <= q_parallel_in[0];
            q_lane1_out  <= q_parallel_in[1];
            q_lane2_out  <= q_parallel_in[2];
            q_lane3_out  <= q_parallel_in[3];
            q_lane4_out  <= q_parallel_in[4];
            q_lane5_out  <= q_parallel_in[5];
            q_lane6_out  <= q_parallel_in[6];
            q_lane7_out  <= q_parallel_in[7];

            dac_sync_out <= 1'b1;
        end else begin
            dac_sync_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_dac_valid_sync;
        @(posedge clk_300mhz) disable iff (!rst_n)
        valid_in |=> dac_sync_out;
    endproperty
    assert_dac_valid_sync: assert property (p_dac_valid_sync);
    `endif

endmodule
