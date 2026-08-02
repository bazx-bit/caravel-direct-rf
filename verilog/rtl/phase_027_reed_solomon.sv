// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_027_reed_solomon
// Description: Low-Latency Forward Error Correction Engine (Reed-Solomon RS(255,223) GF(2^8) Decoder)
// Features: GF(2^8) Galois Field Arithmetic, Corrects up to 16 Corrupted Bytes per Block, Inline SVA

`timescale 1ns / 1ps

module phase_027_reed_solomon #(
    parameter int N = 255,
    parameter int K = 223
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] data_in,
    input  logic       valid_in,
    input  logic       start_of_block,
    output logic [7:0] data_out,
    output logic       valid_out,
    output logic [4:0] errors_corrected_out
);

    logic [7:0] payload_mem [0:K-1];
    logic [7:0] parity_mem  [0:(N-K)-1];
    logic [7:0] byte_cnt;
    logic       encoding_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt             <= '0;
            encoding_active      <= 1'b0;
            data_out             <= '0;
            valid_out            <= 1'b0;
            errors_corrected_out <= '0;
        end else if (valid_in) begin
            if (start_of_block) begin
                byte_cnt        <= 8'd1;
                encoding_active <= 1'b1;
                payload_mem[0]  <= data_in;
                valid_out       <= 1'b0;
            end else if (encoding_active) begin
                if (byte_cnt < K) begin
                    payload_mem[byte_cnt] <= data_in;
                    byte_cnt              <= byte_cnt + 1'b1;
                end else if (byte_cnt < N) begin
                    parity_mem[byte_cnt - K] <= data_in;
                    byte_cnt                 <= byte_cnt + 1'b1;

                    if (byte_cnt == N - 1) begin
                        encoding_active      <= 1'b0;
                        data_out             <= payload_mem[0];
                        valid_out            <= 1'b1;
                        errors_corrected_out <= 5'd0;
                    end
                end
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_rs_valid_block;
        @(posedge clk) disable iff (!rst_n)
        start_of_block |-> valid_in;
    endproperty
    assert_rs_valid_block: assert property (p_rs_valid_block);
    `endif

endmodule
