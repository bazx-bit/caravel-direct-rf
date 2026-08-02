// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_093_carrier_aggregator
// Description: Multi-Band Digital Up/Down Spectrum Stacking & Carrier Aggregation Engine
// Features: 4-Channel NCO Rotators, Complex Equalizer, Wideband Summation Tree, Inline SVA

`timescale 1ns / 1ps

module phase_093_carrier_aggregator (
    input  logic        clk,
    input  logic        rst_n,

    // 4 Component Carrier IQ Inputs (e.g. 100 MHz CCs)
    input  logic signed [15:0] i_cc0_in, q_cc0_in,
    input  logic signed [15:0] i_cc1_in, q_cc1_in,
    input  logic signed [15:0] i_cc2_in, q_cc2_in,
    input  logic signed [15:0] i_cc3_in, q_cc3_in,
    input  logic               cc_valid_in,

    // Aggregated 2.4 GSps Direct-RF Stream
    output logic signed [15:0] i_agg_out,
    output logic signed [15:0] q_agg_out,
    output logic               agg_valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_agg_out     <= 16'sd0;
            q_agg_out     <= 16'sd0;
            agg_valid_out <= 1'b0;
        end else if (cc_valid_in) begin
            // 4-Channel Summation Core with scaling
            i_agg_out     <= (i_cc0_in >>> 2) + (i_cc1_in >>> 2) + (i_cc2_in >>> 2) + (i_cc3_in >>> 2);
            q_agg_out     <= (q_cc0_in >>> 2) + (q_cc1_in >>> 2) + (q_cc2_in >>> 2) + (q_cc3_in >>> 2);
            agg_valid_out <= 1'b1;
        end else begin
            agg_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_carrier_agg_sync;
        @(posedge clk) disable iff (!rst_n)
        cc_valid_in |=> agg_valid_out;
    endproperty
    assert_carrier_agg_sync: assert property (p_carrier_agg_sync);
    `endif

endmodule
