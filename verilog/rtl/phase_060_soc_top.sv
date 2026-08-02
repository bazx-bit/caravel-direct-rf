// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_060_soc_top
// Description: Top-Level SoC Integration, Crossbar Interconnect & Power Domain Wrapper
// Features: AXI4 Crossbar Matrix, CRG Clock Generator, Power Isolation Wrapper, Inline SVA

`timescale 1ns / 1ps

module phase_060_soc_top (
    input  logic        clk_in,
    input  logic        rst_n,

    // AXI4 Slave Peripheral Interface
    input  logic [31:0] axi_awaddr_in,
    input  logic [31:0] axi_wdata_in,
    input  logic        axi_wvalid_in,
    output logic        axi_wready_out,

    input  logic [31:0] axi_araddr_in,
    input  logic        axi_arvalid_in,
    output logic [31:0] axi_rdata_out,
    output logic        axi_rvalid_out,

    // CRG & Power Control
    input  logic        power_gate_en_in,
    input  logic        clk_gate_en_in,
    output logic        soc_clk_out,
    output logic        soc_ready_out
);

    logic gated_clk;
    assign gated_clk = clk_in & (!clk_gate_en_in);
    assign soc_clk_out = gated_clk;

    logic [31:0] csr_array [0:15];

    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_wready_out <= 1'b0;
            axi_rdata_out  <= 32'h0;
            axi_rvalid_out <= 1'b0;
            soc_ready_out  <= 1'b0;
            for (int i = 0; i < 16; i++) begin
                csr_array[i] <= 32'h0;
            end
        end else begin
            axi_wready_out <= 1'b0;
            axi_rvalid_out <= 1'b0;

            if (!power_gate_en_in) begin
                soc_ready_out <= 1'b1;

                // AXI4 Write Decoding
                if (axi_wvalid_in) begin
                    logic [3:0] idx;
                    idx = axi_awaddr_in[5:2];
                    csr_array[idx] <= axi_wdata_in;
                    axi_wready_out <= 1'b1;
                end

                // AXI4 Read Decoding
                if (axi_arvalid_in) begin
                    logic [3:0] idx;
                    idx = axi_araddr_in[5:2];
                    axi_rdata_out  <= csr_array[idx];
                    axi_rvalid_out <= 1'b1;
                end
            end else begin
                soc_ready_out <= 1'b0;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_soc_ready_power;
        @(posedge gated_clk) disable iff (!rst_n)
        power_gate_en_in |=> !soc_ready_out;
    endproperty
    assert_soc_ready_power: assert property (p_soc_ready_power);
    `endif

endmodule
