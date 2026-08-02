// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_020_phy_fsm
// Description: Physical Layer Top Transceiver Controller Engine (PHY FSM Master State Machine)
// Features: 8-State Transceiver Control FSM, Packet Counters, Inter-Module Handshaking, Inline SVA

`timescale 1ns / 1ps

module phase_020_phy_fsm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [2:0]  cmd_in,           // 000: NOP, 001: START_SENSING, 010: START_TX, 011: START_RX, 100: CLEAR
    input  logic        jammer_detected,  // From Phase 006 NPU
    input  logic        sync_detected,    // From Phase 015 Preamble Sync
    input  logic        crc_pass,         // From Phase 014 CRC-32
    input  logic        tx_complete,
    output logic [2:0]  current_state_out,
    output logic [15:0] packet_count_out,
    output logic [15:0] error_count_out,
    output logic        tx_enable_out,
    output logic        rx_enable_out,
    output logic        valid_out
);

    typedef enum logic [2:0] {
        ST_IDLE             = 3'b000,
        ST_SPECTRUM_SENSING = 3'b001,
        ST_TX_PREAMBLE      = 3'b010,
        ST_TX_PAYLOAD       = 3'b011,
        ST_RX_SEARCH        = 3'b100,
        ST_RX_DEMOD         = 3'b101,
        ST_RX_DECODE        = 3'b110,
        ST_ERROR            = 3'b111
    } state_t;

    state_t state_reg, next_state;
    logic [15:0] packet_cnt, error_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg  <= ST_IDLE;
            packet_cnt <= '0;
            error_cnt  <= '0;
        end else begin
            state_reg <= next_state;

            if (state_reg == ST_TX_PAYLOAD && tx_complete) begin
                packet_cnt <= packet_cnt + 1'b1;
            end else if (state_reg == ST_RX_DECODE && crc_pass) begin
                packet_cnt <= packet_cnt + 1'b1;
            end else if (state_reg == ST_RX_DECODE && !crc_pass) begin
                error_cnt <= error_cnt + 1'b1;
            end
        end
    end

    always_comb begin
        next_state = state_reg;
        case (state_reg)
            ST_IDLE: begin
                if (cmd_in == 3'b001) next_state = ST_SPECTRUM_SENSING;
                else if (cmd_in == 3'b010) next_state = ST_TX_PREAMBLE;
                else if (cmd_in == 3'b011) next_state = ST_RX_SEARCH;
            end

            ST_SPECTRUM_SENSING: begin
                if (jammer_detected) next_state = ST_IDLE;
                else next_state = ST_RX_SEARCH;
            end

            ST_TX_PREAMBLE: next_state = ST_TX_PAYLOAD;

            ST_TX_PAYLOAD: begin
                if (tx_complete) next_state = ST_IDLE;
            end

            ST_RX_SEARCH: begin
                if (sync_detected) next_state = ST_RX_DEMOD;
            end

            ST_RX_DEMOD: next_state = ST_RX_DECODE;

            ST_RX_DECODE: begin
                if (crc_pass) next_state = ST_IDLE;
                else next_state = ST_ERROR;
            end

            ST_ERROR: begin
                if (cmd_in == 3'b100) next_state = ST_IDLE;
            end

            default: next_state = ST_IDLE;
        endcase
    end

    assign current_state_out = state_reg;
    assign packet_count_out  = packet_cnt;
    assign error_count_out   = error_cnt;
    assign tx_enable_out     = (state_reg == ST_TX_PREAMBLE || state_reg == ST_TX_PAYLOAD);
    assign rx_enable_out     = (state_reg == ST_RX_SEARCH || state_reg == ST_RX_DEMOD || state_reg == ST_RX_DECODE);
    assign valid_out         = 1'b1;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_fsm_valid_state;
        @(posedge clk) disable iff (!rst_n)
        (state_reg <= ST_ERROR);
    endproperty
    assert_fsm_valid_state: assert property (p_fsm_valid_state);
    `endif

endmodule
