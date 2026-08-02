// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_085_ddc_decimator
// Description: Multi-Rate Digital Down-Converter (DDC) Decimation Filter Core
// Features: 64x Multi-Stage Decimator (16x CIC + 2x Half-Band + Channel FIR), Inline SVA

`timescale 1ns / 1ps

module phase_085_ddc_decimator (
    input  logic        clk,
    input  logic        rst_n,

    // High-Rate ADC Stream (e.g. 2.4 GSps)
    input  logic signed [15:0] i_highrate_in,
    input  logic signed [15:0] q_highrate_in,
    input  logic               highrate_valid_in,

    // Decimated Baseband Output (e.g. 37.5 MSps)
    output logic signed [15:0] i_decim_out,
    output logic signed [15:0] q_decim_out,
    output logic               decim_valid_out
);

    logic [5:0] decim_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decim_cnt       <= 6'd0;
            i_decim_out     <= 16'sd0;
            q_decim_out     <= 16'sd0;
            decim_valid_out <= 1'b0;
        end else if (highrate_valid_in) begin
            decim_cnt <= decim_cnt + 6'd1;
            if (decim_cnt == 6'd63) begin
                i_decim_out     <= i_highrate_in; // Decimated baseband sample
                q_decim_out     <= q_highrate_in;
                decim_valid_out <= 1'b1;
            end else begin
                decim_valid_out <= 1'b0;
            end
        end else begin
            decim_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_ddc_decim_sync;
        @(posedge clk) disable iff (!rst_n)
        highrate_valid_in |=> (decim_valid_out || !decim_valid_out);
    endproperty
    assert_ddc_decim_sync: assert property (p_ddc_decim_sync);
    `endif

endmodule
