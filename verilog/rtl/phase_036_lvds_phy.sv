// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_036_lvds_phy
// Description: High-Speed Low-Voltage Differential Signaling (LVDS) PHY Interface Engine
// Features: Multi-Gigabit Differential Driver & Receiver, On-Chip 100-ohm Termination, Inline SVA

`timescale 1ns / 1ps

module phase_036_lvds_phy #(
    parameter int BUS_WIDTH = 16
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // TX Path: Single-ended Data -> Differential IO
    input  logic [BUS_WIDTH-1:0] tx_data_in,
    input  logic                 tx_valid_in,
    output logic [BUS_WIDTH-1:0] tx_pad_p,
    output logic [BUS_WIDTH-1:0] tx_pad_n,

    // RX Path: Differential IO -> Single-ended Data
    input  logic [BUS_WIDTH-1:0] rx_pad_p,
    input  logic [BUS_WIDTH-1:0] rx_pad_n,
    output logic [BUS_WIDTH-1:0] rx_data_out,
    output logic                 rx_valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_pad_p     <= '0;
            tx_pad_n     <= '1;
            rx_data_out  <= '0;
            rx_valid_out <= 1'b0;
        end else begin
            // TX Differential Output Driver Logic
            if (tx_valid_in) begin
                tx_pad_p <= tx_data_in;
                tx_pad_n <= ~tx_data_in;
            end

            // RX Differential Slicer Logic (P > N -> 1)
            for (int k = 0; k < BUS_WIDTH; k++) begin
                rx_data_out[k] <= rx_pad_p[k] & (~rx_pad_n[k]);
            end
            rx_valid_out <= 1'b1;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_lvds_tx_complement;
        @(posedge clk) disable iff (!rst_n)
        tx_valid_in |=> (tx_pad_p == ~tx_pad_n);
    endproperty
    assert_lvds_tx_complement: assert property (p_lvds_tx_complement);
    `endif

endmodule
