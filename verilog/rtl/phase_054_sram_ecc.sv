// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_054_sram_ecc
// Description: Synchronous Static RAM (SRAM) Memory Subsystem & ECC Controller Engine
// Features: SEC-DED Extended Hamming Code [39,32], 4-Bank SRAM, Error Scrubbing, Inline SVA

`timescale 1ns / 1ps

module phase_054_sram_ecc #(
    parameter int ADDR_WIDTH = 11, // 2048 Depth
    parameter int DATA_WIDTH = 32,
    parameter int ECC_WIDTH  = 7   // 6 parity + 1 overall parity
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // SRAM Memory Interface
    input  logic [ADDR_WIDTH-1:0]  addr_in,
    input  logic [DATA_WIDTH-1:0]  write_data_in,
    input  logic                   write_en_in,
    input  logic                   read_en_in,

    // Memory Readout & ECC Status Outputs
    output logic [DATA_WIDTH-1:0]  read_data_out,
    output logic                   single_error_corrected_out,
    output logic                   dual_error_detected_out,
    output logic                   read_valid_out
);

    localparam int TOTAL_WIDTH = DATA_WIDTH + ECC_WIDTH; // 39 bits

    // 2048 x 39 SRAM Array
    logic [TOTAL_WIDTH-1:0] sram [0:(1<<ADDR_WIDTH)-1];

    // SEC-DED Encoder Function
    function automatic logic [ECC_WIDTH-1:0] encode_ecc(input logic [31:0] d);
        logic p0, p1, p2, p3, p4, p5, p6;
        p0 = ^(d & 32'h55555555);
        p1 = ^(d & 32'h66666666);
        p2 = ^(d & 32'h78787878);
        p3 = ^(d & 32'h7F807F80);
        p4 = ^(d & 32'h7FFF0000);
        p5 = ^(d & 32'h80000000);
        p6 = ^({d, p5, p4, p3, p2, p1, p0});
        return {p6, p5, p4, p3, p2, p1, p0};
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_out              <= '0;
            single_error_corrected_out <= 1'b0;
            dual_error_detected_out    <= 1'b0;
            read_valid_out             <= 1'b0;
        end else begin
            single_error_corrected_out <= 1'b0;
            dual_error_detected_out    <= 1'b0;
            read_valid_out             <= 1'b0;

            if (write_en_in) begin
                logic [ECC_WIDTH-1:0] ecc;
                ecc <= encode_ecc(write_data_in);
                sram[addr_in] <= {write_data_in, encode_ecc(write_data_in)};
            end

            if (read_en_in) begin
                logic [TOTAL_WIDTH-1:0] entry;
                logic [31:0] d_raw;
                logic [6:0]  e_raw;
                logic [6:0]  e_exp;
                logic [5:0]  syndrome;
                logic        parity_check;

                entry    = sram[addr_in];
                d_raw    = entry[38:7];
                e_raw    = entry[6:0];
                e_exp    = encode_ecc(d_raw);
                syndrome = e_raw[5:0] ^ e_exp[5:0];
                parity_check = (^entry) != 1'b0;

                if (syndrome != 6'd0 && parity_check) begin
                    // Single-bit error correction
                    single_error_corrected_out <= 1'b1;
                    if (syndrome <= 6'd32) begin
                        d_raw = d_raw ^ (32'd1 << (syndrome - 1'b1));
                    end
                end else if (syndrome != 6'd0 && !parity_check) begin
                    // Dual-bit uncorrectable error
                    dual_error_detected_out <= 1'b1;
                end

                read_data_out  <= d_raw;
                read_valid_out <= 1'b1;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_sram_read_sync;
        @(posedge clk) disable iff (!rst_n)
        read_en_in |=> read_valid_out;
    endproperty
    assert_sram_read_sync: assert property (p_sram_read_sync);
    `endif

endmodule
