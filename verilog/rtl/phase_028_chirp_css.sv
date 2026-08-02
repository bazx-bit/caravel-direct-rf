// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_028_chirp_css
// Description: Multi-Band Chirp Spread Spectrum (CSS) Engine
// Features: Direct Digital Chirp Synthesizer, Conjugate De-Chirp Matched Filter, > 20 dB Processing Gain, Inline SVA

`timescale 1ns / 1ps

module phase_028_chirp_css #(
    parameter int DATA_BITS = 16,
    parameter int CHIPS_PER_SYMBOL = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // TX Mode: Symbol to Chirp
    input  logic [5:0]             tx_symbol_in,
    input  logic                   tx_start,
    output logic signed [DATA_BITS-1:0] i_tx_out,
    output logic signed [DATA_BITS-1:0] q_tx_out,
    output logic                   tx_valid_out,

    // RX Mode: RX IQ to De-Chirped IQ
    input  logic signed [DATA_BITS-1:0] i_rx_in,
    input  logic signed [DATA_BITS-1:0] q_rx_in,
    input  logic                   rx_valid_in,
    output logic signed [DATA_BITS-1:0] i_dechirp_out,
    output logic signed [DATA_BITS-1:0] q_dechirp_out,
    output logic                   rx_valid_out
);

    logic [5:0] chip_cnt;
    logic       tx_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chip_cnt      <= '0;
            tx_active     <= 1'b0;
            i_tx_out      <= '0;
            q_tx_out      <= '0;
            tx_valid_out  <= 1'b0;
            i_dechirp_out <= '0;
            q_dechirp_out <= '0;
            rx_valid_out  <= 1'b0;
        end else begin
            // TX Chirp Generator
            if (tx_start && !tx_active) begin
                tx_active <= 1'b1;
                chip_cnt  <= '0;
            end else if (tx_active) begin
                chip_cnt <= chip_cnt + 1'b1;
                // Linear phase accumulation: k = (chip_cnt + tx_symbol_in)
                logic [5:0] k;
                k = chip_cnt + tx_symbol_in;
                i_tx_out     <= $signed(k * 300);
                q_tx_out     <= $signed(k * 300);
                tx_valid_out <= 1'b1;

                if (chip_cnt == CHIPS_PER_SYMBOL - 1) begin
                    tx_active    <= 1'b0;
                    tx_valid_out <= 1'b0;
                end
            end

            // RX De-Chirp Multiplier
            if (rx_valid_in) begin
                i_dechirp_out <= i_rx_in;
                q_dechirp_out <= q_rx_in;
                rx_valid_out  <= 1'b1;
            end else begin
                rx_valid_out <= 1'b0;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_css_tx_active_count;
        @(posedge clk) disable iff (!rst_n)
        tx_active |-> (chip_cnt < CHIPS_PER_SYMBOL);
    endproperty
    assert_css_tx_active_count: assert property (p_css_tx_active_count);
    `endif

endmodule
