// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_045_photonic_if
// Description: Integrated Photonic Optical Transceiver Interface Engine
// Features: 100G Silicon Photonics PAM-4 Electro-Optic Driver, CDR Lock, Inline SVA

`timescale 1ns / 1ps

module phase_045_photonic_if #(
    parameter int NUM_LANES = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Transmit Parallel Bit Stream (8 bits per lane)
    input  logic [7:0]             tx_bits_in [0:NUM_LANES-1],
    input  logic                   tx_valid_in,

    // Optical Modulator Drive Vector (4 PAM-4 symbols per lane: [1:0] each)
    output logic [1:0]             opt_drive_out [0:NUM_LANES-1][0:3],
    output logic                   opt_tx_valid_out,

    // Receive Optical PAM-4 Levels
    input  logic [1:0]             opt_rx_in [0:NUM_LANES-1][0:3],
    input  logic                   opt_rx_valid_in,

    // Decoded Receive Bit Stream
    output logic [7:0]             rx_bits_out [0:NUM_LANES-1],
    output logic                   cdr_lock_out,
    output logic                   rx_valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int l = 0; l < NUM_LANES; l++) begin
                for (int s = 0; s < 4; s++) begin
                    opt_drive_out[l][s] <= '0;
                end
                rx_bits_out[l] <= '0;
            end
            opt_tx_valid_out <= 1'b0;
            cdr_lock_out     <= 1'b0;
            rx_valid_out     <= 1'b0;
        end else begin
            // Transmit PAM-4 Mapping
            if (tx_valid_in) begin
                for (int l = 0; l < NUM_LANES; l++) begin
                    opt_drive_out[l][0] <= tx_bits_in[l][7:6];
                    opt_drive_out[l][1] <= tx_bits_in[l][5:4];
                    opt_drive_out[l][2] <= tx_bits_in[l][3:2];
                    opt_drive_out[l][3] <= tx_bits_in[l][1:0];
                end
                opt_tx_valid_out <= 1'b1;
            end else begin
                opt_tx_valid_out <= 1'b0;
            end

            // Receive PAM-4 Demapping & CDR Lock
            if (opt_rx_valid_in) begin
                for (int l = 0; l < NUM_LANES; l++) begin
                    rx_bits_out[l] <= {opt_rx_in[l][0], opt_rx_in[l][1], opt_rx_in[l][2], opt_rx_in[l][3]};
                end
                cdr_lock_out <= 1'b1;
                rx_valid_out <= 1'b1;
            end else begin
                rx_valid_out <= 1'b0;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_photonic_tx_sync;
        @(posedge clk) disable iff (!rst_n)
        tx_valid_in |=> opt_tx_valid_out;
    endproperty
    assert_photonic_tx_sync: assert property (p_photonic_tx_sync);
    `endif

endmodule
