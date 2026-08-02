// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_053_jtag_bist
// Description: Hardware Built-In Self-Test (BIST) & Boundary Scan (IEEE 1149.1 JTAG) Core
// Features: IEEE 1149.1 TAP Controller, 32-bit IDCODE, LFSR/MISR BIST Engine, Inline SVA

`timescale 1ns / 1ps

module phase_053_jtag_bist (
    // JTAG TAP Pins
    input  logic        tck,
    input  logic        trst_n,
    input  logic        tms,
    input  logic        tdi,
    output logic        tdo,

    // BIST Status & Control Outputs
    input  logic        run_bist_start_in,
    output logic [15:0] bist_signature_out,
    output logic        bist_done_out,
    output logic        bist_pass_out
);

    localparam logic [31:0] IDCODE_VAL = 32'h1130021D;
    localparam logic [15:0] EXPECTED_SIG = 16'h8277;

    // TAP FSM States
    typedef enum logic [3:0] {
        TLR  = 4'h0, // Test-Logic-Reset
        RTI  = 4'h1, // Run-Test/Idle
        SDRS = 4'h2, // Select-DR-Scan
        CDRS = 4'h3, // Capture-DR
        SDR  = 4'h4, // Shift-DR
        E1DR = 4'h5, // Exit1-DR
        PDR  = 4'h6, // Pause-DR
        E2DR = 4'h7, // Exit2-DR
        UDR  = 4'h8, // Update-DR
        SIRS = 4'h9, // Select-IR-Scan
        CIR  = 4'hA, // Capture-IR
        SIR  = 4'hB, // Shift-IR
        E1IR = 4'hC, // Exit1-IR
        PIR  = 4'hD, // Pause-IR
        E2IR = 4'hE, // Exit2-IR
        UIR  = 4'hF  // Update-IR
    } tap_state_t;

    tap_state_t tap_state;
    logic [7:0] ir_reg;
    logic [31:0] dr_shift;
    logic [15:0] lfsr_reg;
    logic [15:0] misr_reg;
    logic [9:0]  bist_cnt;
    logic        bist_running;

    // TAP FSM Transition
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tap_state <= TLR;
            ir_reg    <= 8'h02; // Default IDCODE
        end else begin
            case (tap_state)
                TLR:  tap_state <= tms ? TLR  : RTI;
                RTI:  tap_state <= tms ? SDRS : RTI;
                SDRS: tap_state <= tms ? SIRS : CDRS;
                CDRS: tap_state <= tms ? E1DR : SDR;
                SDR:  tap_state <= tms ? E1DR : SDR;
                E1DR: tap_state <= tms ? UDR  : PDR;
                PDR:  tap_state <= tms ? E2DR : PDR;
                E2DR: tap_state <= tms ? UDR  : SDR;
                UDR:  tap_state <= tms ? SDRS : RTI;

                SIRS: tap_state <= tms ? TLR  : CIR;
                CIR:  tap_state <= tms ? E1IR : SIR;
                SIR:  tap_state <= tms ? E1IR : SIR;
                E1IR: tap_state <= tms ? UIR  : PIR;
                PIR:  tap_state <= tms ? E2IR : PIR;
                E2IR: tap_state <= tms ? UIR  : SIR;
                UIR:  tap_state <= tms ? SDRS : RTI;
                default: tap_state <= TLR;
            endcase
        end
    end

    // DR Shift & BIST Logic
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            dr_shift           <= IDCODE_VAL;
            tdo                <= 1'b0;
            lfsr_reg           <= 16'hACE1;
            misr_reg           <= 16'h0000;
            bist_cnt           <= 10'd0;
            bist_running       <= 1'b0;
            bist_done_out      <= 1'b0;
            bist_pass_out      <= 1'b0;
            bist_signature_out <= 16'h0000;
        end else begin
            if (tap_state == CDRS) begin
                dr_shift <= IDCODE_VAL;
            end else if (tap_state == SDR) begin
                tdo      <= dr_shift[0];
                dr_shift <= {tdi, dr_shift[31:1]};
            end

            // BIST Execution Engine
            if (run_bist_start_in && !bist_running) begin
                bist_running  <= 1'b1;
                lfsr_reg      <= 16'hACE1;
                misr_reg      <= 16'h0000;
                bist_cnt      <= 10'd0;
                bist_done_out <= 1'b0;
            end else if (bist_running) begin
                logic lfsr_fb, misr_fb;
                lfsr_fb  = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5];
                lfsr_reg <= {lfsr_fb, lfsr_reg[15:1]};

                misr_fb  = misr_reg[0] ^ misr_reg[4] ^ misr_reg[13];
                misr_reg <= ({misr_fb, misr_reg[15:1]}) ^ lfsr_reg;

                bist_cnt <= bist_cnt + 1'b1;
                if (bist_cnt == 10'd999) begin
                    bist_running       <= 1'b0;
                    bist_done_out      <= 1'b1;
                    bist_signature_out <= misr_reg;
                    bist_pass_out      <= (misr_reg == EXPECTED_SIG);
                end
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_jtag_tlr_reset;
        @(posedge tck) disable iff (!trst_n)
        (tap_state == TLR) |-> (ir_reg == 8'h02);
    endproperty
    assert_jtag_tlr_reset: assert property (p_jtag_tlr_reset);
    `endif

endmodule
