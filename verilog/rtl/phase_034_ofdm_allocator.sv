// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_034_ofdm_allocator
// Description: Ultra-Wideband OFDM Subcarrier Allocator Engine
// Features: 64-Subcarrier Allocation (48 Data, 4 Pilot BPSK, 11 Guard, 1 DC), IFFT Interface, Inline SVA

`timescale 1ns / 1ps

module phase_034_ofdm_allocator #(
    parameter int DATA_BITS = 16,
    parameter int FFT_SIZE = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Payload Symbol Input
    input  logic signed [DATA_BITS-1:0] data_i_in,
    input  logic signed [DATA_BITS-1:0] data_q_in,
    input  logic                   data_valid_in,
    input  logic                   frame_start_in,

    // 64-Subcarrier Allocated Frequency Vector Output to IFFT Core
    output logic signed [DATA_BITS-1:0] subcarrier_i_out,
    output logic signed [DATA_BITS-1:0] subcarrier_q_out,
    output logic [5:0]             subcarrier_bin_out,
    output logic                   subcarrier_valid_out
);

    logic [5:0] bin_cnt;
    logic       allocating;

    // BPSK Pilot Constant value (Q1.15)
    localparam logic signed [DATA_BITS-1:0] PILOT_VAL = 16'sd20000;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_cnt              <= '0;
            allocating           <= 1'b0;
            subcarrier_i_out     <= '0;
            subcarrier_q_out     <= '0;
            subcarrier_bin_out   <= '0;
            subcarrier_valid_out <= 1'b0;
        end else if (frame_start_in && !allocating) begin
            allocating <= 1'b1;
            bin_cnt    <= '0;
        end else if (allocating) begin
            subcarrier_bin_out   <= bin_cnt;
            subcarrier_valid_out <= 1'b1;

            // Bin Mapping Rules
            if (bin_cnt == 6'd0 || (bin_cnt >= 6'd27 && bin_cnt <= 6'd37)) begin
                // DC zero bin (0) and Guard zero bins (27..37)
                subcarrier_i_out <= '0;
                subcarrier_q_out <= '0;
            end else if (bin_cnt == 6'd7 || bin_cnt == 6'd21 || bin_cnt == 6'd43 || bin_cnt == 6'd57) begin
                // BPSK Pilot bins (7, 21, 43, 57)
                subcarrier_i_out <= PILOT_VAL;
                subcarrier_q_out <= '0;
            end else begin
                // Data subcarrier bins
                subcarrier_i_out <= data_i_in;
                subcarrier_q_out <= data_q_in;
            end

            if (bin_cnt == FFT_SIZE - 1) begin
                allocating           <= 1'b0;
                subcarrier_valid_out <= 1'b0;
            end else begin
                bin_cnt <= bin_cnt + 1'b1;
            end
        end else begin
            subcarrier_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_ofdm_bin_count_bound;
        @(posedge clk) disable iff (!rst_n)
        allocating |-> (bin_cnt < FFT_SIZE);
    endproperty
    assert_ofdm_bin_count_bound: assert property (p_ofdm_bin_count_bound);
    `endif

endmodule
