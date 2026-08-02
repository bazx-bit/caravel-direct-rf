// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_024_ptp
// Description: IEEE 1588 Precision Time Protocol (PTP) Hardware Timestamp Engine
// Features: 64-Bit Free-Running Sub-NS Counter, Ingress/Egress Latch Registers, Offset/Delay Calculator, Inline SVA

`timescale 1ns / 1ps

module phase_024_ptp #(
    parameter int TIMESTAMP_BITS = 64
)(
    input  logic                      clk,
    input  logic                      rst_n,

    // Frame Strobe Inputs
    input  logic                      tx_sync_strobe,   // Captures T1
    input  logic                      rx_sync_strobe,   // Captures T2
    input  logic                      tx_resp_strobe,   // Captures T3
    input  logic                      rx_resp_strobe,   // Captures T4

    // Clock Correction Interface
    input  logic signed [31:0]        clock_adj_in,
    input  logic                      clock_adj_valid,

    // Computed Time Outputs
    output logic [TIMESTAMP_BITS-1:0] rtc_counter_out,
    output logic signed [31:0]        calculated_offset_out,
    output logic signed [31:0]        calculated_delay_out,
    output logic                      calc_valid_out
);

    logic [TIMESTAMP_BITS-1:0] rtc_counter;
    logic [TIMESTAMP_BITS-1:0] t1_reg, t2_reg, t3_reg, t4_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rtc_counter             <= '0;
            t1_reg                  <= '0;
            t2_reg                  <= '0;
            t3_reg                  <= '0;
            t4_reg                  <= '0;
            calculated_offset_out   <= '0;
            calculated_delay_out    <= '0;
            calc_valid_out          <= 1'b0;
        end else begin
            // Advance 64-bit RTC counter
            if (clock_adj_valid) begin
                rtc_counter <= rtc_counter + 1'b1 + $signed(clock_adj_in);
            end else begin
                rtc_counter <= rtc_counter + 1'b1;
            end

            // Capture timestamps
            if (tx_sync_strobe) t1_reg <= rtc_counter;
            if (rx_sync_strobe) t2_reg <= rtc_counter;
            if (tx_resp_strobe) t3_reg <= rtc_counter;
            if (rx_resp_strobe) begin
                t4_reg <= rtc_counter;

                // Execute IEEE 1588 Offset & Delay calculation
                logic signed [63:0] dt_fwd, dt_rev;
                dt_fwd = t2_reg - t1_reg;
                dt_rev = rtc_counter - t3_reg;

                calculated_offset_out <= (dt_fwd - dt_rev) >>> 1;
                calculated_delay_out  <= (dt_fwd + dt_rev) >>> 1;
                calc_valid_out        <= 1'b1;
            end else begin
                calc_valid_out <= 1'b0;
            end
        end
    end

    assign rtc_counter_out = rtc_counter;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_ptp_rtc_monotonic;
        @(posedge clk) disable iff (!rst_n || clock_adj_valid)
        rtc_counter |=> (rtc_counter > $past(rtc_counter));
    endproperty
    assert_ptp_rtc_monotonic: assert property (p_ptp_rtc_monotonic);
    `endif

endmodule
