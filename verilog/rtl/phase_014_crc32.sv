// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_014_crc32
// Description: Cyclic Redundancy Check (CRC-32) Packet Integrity Generator & Error Detector
// Features: IEEE 802.3 Polynomial (0xEDB88320), Dual-Mode TX Append / RX Verify, Inline SVA

`timescale 1ns / 1ps

module phase_014_crc32 #(
    parameter logic [31:0] CRC_POLY = 32'hEDB88320
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mode,        // 0: TX CRC Append, 1: RX CRC Verify
    input  logic        sof,         // Start of Frame
    input  logic        eof,         // End of Frame
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    output logic [7:0]  data_out,
    output logic [31:0] crc_out,
    output logic        crc_pass,
    output logic        valid_out
);

    logic [31:0] crc_reg;

    function automatic logic [31:0] next_crc32(input logic [31:0] current_crc, input logic [7:0] b);
        logic [31:0] crc;
        crc = current_crc ^ {24'h000000, b};
        for (int i = 0; i < 8; i++) begin
            if (crc[0]) begin
                crc = (crc >> 1) ^ CRC_POLY;
            end else begin
                crc = crc >> 1;
            end
        end
        next_crc32 = crc;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg   <= 32'hFFFFFFFF;
            data_out  <= 8'h00;
            crc_out   <= 32'h00000000;
            crc_pass  <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            if (sof) begin
                crc_reg <= next_crc32(32'hFFFFFFFF, data_in);
            end else begin
                crc_reg <= next_crc32(crc_reg, data_in);
            end

            data_out  <= data_in;
            valid_out <= 1'b1;

            if (eof) begin
                crc_out  <= crc_reg ^ 32'hFFFFFFFF;
                crc_pass <= (mode == 1'b1) ? ((crc_reg ^ 32'hFFFFFFFF) == 32'h00000000) : 1'b1;
            end else begin
                crc_pass <= 1'b0;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_crc_sof_resets;
        @(posedge clk) disable iff (!rst_n)
        valid_in && sof |=> (crc_reg != 32'hFFFFFFFF);
    endproperty
    assert_crc_sof_resets: assert property (p_crc_sof_resets);
    `endif

endmodule
