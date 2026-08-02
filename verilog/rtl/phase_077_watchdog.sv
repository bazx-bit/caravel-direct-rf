// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_077_watchdog
// Description: Autonomous On-Chip Watchdog Timer & System Health Monitor Engine
// Features: Multi-Stage Cascaded Watchdog, Heartbeat Monitor, NMI Escalation, System Reset Output, Inline SVA

`timescale 1ns / 1ps

module phase_077_watchdog (
    input  logic        clk,
    input  logic        rst_n,

    // Controls & Kicks
    input  logic        wdt_kick_in,
    input  logic        heartbeat_pulse_in,
    input  logic        wdt_enable_in,

    // Status & Interrupt Escalation Outputs
    output logic        warning_irq_out,
    output logic        nmi_out,
    output logic        system_reset_out,
    output logic [1:0]  wdt_state_out,
    output logic        wdt_valid_out
);

    // Watchdog States: 2'b00 = IDLE/OK, 2'b01 = WARNING, 2'b10 = NMI, 2'b11 = RESET
    logic [19:0] timer_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_cnt        <= 20'd0;
            warning_irq_out  <= 1'b0;
            nmi_out          <= 1'b0;
            system_reset_out <= 1'b0;
            wdt_state_out    <= 2'b00;
            wdt_valid_out    <= 1'b0;
        end else if (wdt_enable_in) begin
            wdt_valid_out <= 1'b1;
            if (wdt_kick_in || heartbeat_pulse_in) begin
                timer_cnt        <= 20'd0;
                warning_irq_out  <= 1'b0;
                nmi_out          <= 1'b0;
                system_reset_out <= 1'b0;
                wdt_state_out    <= 2'b00;
            end else begin
                timer_cnt <= timer_cnt + 20'd1;

                if (timer_cnt >= 20'd300000) begin
                    system_reset_out <= 1'b1;
                    wdt_state_out    <= 2'b11; // Hard Reset
                end else if (timer_cnt >= 20'd150000) begin
                    nmi_out       <= 1'b1;
                    wdt_state_out <= 2'b10; // NMI Escalation
                end else if (timer_cnt >= 20'd30000) begin
                    warning_irq_out <= 1'b1;
                    wdt_state_out   <= 2'b01; // Stage 1 Warning
                end
            end
        end else begin
            wdt_valid_out    <= 1'b0;
            warning_irq_out  <= 1'b0;
            nmi_out          <= 1'b0;
            system_reset_out <= 1'b0;
            wdt_state_out    <= 2'b00;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_wdt_sync;
        @(posedge clk) disable iff (!rst_n)
        wdt_enable_in |=> wdt_valid_out;
    endproperty
    assert_wdt_sync: assert property (p_wdt_sync);
    `endif

endmodule
