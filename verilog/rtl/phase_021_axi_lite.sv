// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// Synthesizable AXI4-Lite Slave Register File Architecture
// Module: phase_021_axi_lite

`timescale 1ns / 1ps

module phase_021_axi_lite (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // Write Address Channel
    input  logic [5:0]  s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // Write Data Channel
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // Write Response Channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // Read Address Channel
    input  logic [5:0]  s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // Read Data Channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // Hardware Status Inputs to be read via AXI registers
    input  logic [31:0] phy_status_in,
    input  logic [31:0] packet_count_in,
    input  logic [31:0] error_count_in,

    // Control Outputs driven by AXI write operations
    output logic [31:0] reg_nco_ftw_out,
    output logic [31:0] reg_mod_type_out,
    output logic [31:0] reg_agc_target_out,
    output logic [31:0] reg_npu_thresh_out,
    output logic [31:0] reg_phy_cmd_out
);

    // Internal Slave Control Registers
    logic [31:0] slv_reg_control;    // Offset 0x00
    logic [31:0] slv_reg_nco_ftw;    // Offset 0x04
    logic [31:0] slv_reg_mod_type;   // Offset 0x08
    logic [31:0] slv_reg_agc_target; // Offset 0x0C
    logic [31:0] slv_reg_npu_thresh; // Offset 0x10
    logic [31:0] slv_reg_phy_cmd;    // Offset 0x14

    // Internal Write/Read Handshake Logic
    logic [5:0]  axi_awaddr;
    logic        axi_awready;
    logic        axi_wready;
    logic [1:0]  axi_bresp;
    logic        axi_bvalid;
    logic [5:0]  axi_araddr;
    logic        axi_arready;
    logic [31:0] axi_rdata;
    logic [1:0]  axi_rresp;
    logic        axi_rvalid;

    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = 2'b00; // OKAY response
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00; // OKAY response
    assign s_axi_rvalid  = axi_rvalid;

    // Write Address & Data Handshake
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_awaddr  <= '0;
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_axi_awaddr;
            end else begin
                axi_awready <= 1'b0;
            end

            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Write Register Logic
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            slv_reg_control    <= 32'h0000_0001;
            slv_reg_nco_ftw    <= 32'h0AAA_AAAA;
            slv_reg_mod_type   <= 32'h0000_0002;
            slv_reg_agc_target <= 32'h0000_2000;
            slv_reg_npu_thresh <= 32'h0000_0080;
            slv_reg_phy_cmd    <= 32'h0000_0000;
        end else if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
            case (axi_awaddr[5:2])
                4'h0: slv_reg_control    <= s_axi_wdata;
                4'h1: slv_reg_nco_ftw    <= s_axi_wdata;
                4'h2: slv_reg_mod_type   <= s_axi_wdata;
                4'h3: slv_reg_agc_target <= s_axi_wdata;
                4'h4: slv_reg_npu_thresh <= s_axi_wdata;
                4'h5: slv_reg_phy_cmd    <= s_axi_wdata;
                default: ;
            endcase
        end
    end

    // Write Response Generation
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // Read Address & Read Data Logic
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rdata   <= '0;
            axi_araddr  <= '0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end

            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                case (axi_araddr[5:2])
                    4'h0: axi_rdata <= slv_reg_control;
                    4'h1: axi_rdata <= slv_reg_nco_ftw;
                    4'h2: axi_rdata <= slv_reg_mod_type;
                    4'h3: axi_rdata <= slv_reg_agc_target;
                    4'h4: axi_rdata <= slv_reg_npu_thresh;
                    4'h5: axi_rdata <= slv_reg_phy_cmd;
                    4'h6: axi_rdata <= phy_status_in;
                    4'h7: axi_rdata <= packet_count_in;
                    4'h8: axi_rdata <= error_count_in;
                    default: axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Drive Control Output Ports
    assign reg_nco_ftw_out    = slv_reg_nco_ftw;
    assign reg_mod_type_out   = slv_reg_mod_type;
    assign reg_agc_target_out = slv_reg_agc_target;
    assign reg_npu_thresh_out = slv_reg_npu_thresh;
    assign reg_phy_cmd_out    = slv_reg_phy_cmd;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    `ifndef VERILATOR
    property p_axi_bvalid_handshake;
        @(posedge s_axi_aclk) disable iff (!s_axi_aresetn)
        s_axi_bvalid |-> ##[0:10] (s_axi_bready || !s_axi_bvalid);
    endproperty
    assert_axi_bvalid_handshake: assert property (p_axi_bvalid_handshake);
    `endif
    `endif

endmodule
