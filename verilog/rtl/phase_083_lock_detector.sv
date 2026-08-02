// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_083_lock_detector
// Description: Low-Power Sub-Sampling Phase Lock Indicator & Frequency Lock Detector
// Features: Dual-Window Frequency/Phase Comparators, Sub-us Lock Time, Inline SVA

`timescale 1ns / 1ps

module phase_083_lock_detector (
    input  logic        clk,
    input  logic        rst_n,

    // Reference & Feedback Inputs
    input  logic [15:0] freq_err_hz_in,    // Measured frequency error in Hz
    input  logic [15:0] phase_err_x100_in, // Measured phase error in deg x100 (e.g. 25 = 0.25 deg)
    input  logic        enable_in,

    // Lock Status Outputs
    output logic        freq_lock_out,
    output logic        phase_lock_out,
    output logic        lock_confirmed_out,
    output logic        lock_valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_lock_out      <= 1'b0;
            phase_lock_out     <= 1'b0;
            lock_confirmed_out <= 1'b0;
            lock_valid_out     <= 1'b0;
        end else if (enable_in) begin
            lock_valid_out <= 1'b1;
            // Frequency Lock Window: < 100 Hz
            freq_lock_out  <= (freq_err_hz_in < 16'd100);
            // Phase Lock Window: < 0.50 deg (50 x100)
            phase_lock_out <= (phase_err_x100_in < 16'd50);
            // Lock Confirmed: Both freq and phase locked
            lock_confirmed_out <= (freq_err_hz_in < 16'd100) && (phase_err_x100_in < 16'd50);
        end else begin
            lock_valid_out     <= 1'b0;
            freq_lock_out      <= 1'b0;
            phase_lock_out     <= 1'b0;
            lock_confirmed_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_lock_detector_sync;
        @(posedge clk) disable iff (!rst_n)
        enable_in |=> lock_valid_out;
    endproperty
    assert_lock_detector_sync: assert property (p_lock_detector_sync);
    `endif

endmodule
