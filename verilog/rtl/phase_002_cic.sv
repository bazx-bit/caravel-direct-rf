// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_002_cic
// Description: 5-Stage Cascaded Integrator-Comb (CIC) Decimation Filter
// Features: Parameterized Stages (N=5), Hogenauer Bit-Growth (46-bit accumulators), Inline SVA Assertions

`timescale 1ns / 1ps

module phase_002_cic #(
    parameter int STAGES      = 5,
    parameter int INPUT_BITS  = 16,
    parameter int ACCUM_BITS  = 46,  // 16 + 5*log2(64) = 46 bits for zero overflow
    parameter int OUTPUT_BITS = 16,
    parameter int SHIFT_BITS  = 20   // Bit pruning right-shift for R=16 (16^5 gain scaling)
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [5:0]             decim_rate, // R = 8, 16, 32, 64
    input  logic signed [INPUT_BITS-1:0] data_in,
    input  logic                   valid_in,
    output logic signed [OUTPUT_BITS-1:0] data_out,
    output logic                   valid_out
);

    // Integrator Pipeline Signals (High Rate)
    logic signed [ACCUM_BITS-1:0] int_reg [0:STAGES-1];

    // Decimation Rate Counter
    logic [5:0] rate_cnt;
    logic       decim_strobe;

    // Comb Pipeline Signals (Decimated Rate)
    logic signed [ACCUM_BITS-1:0] comb_reg [0:STAGES-1];
    logic signed [ACCUM_BITS-1:0] comb_delay [0:STAGES-1];

    // Sign-extended Input
    logic signed [ACCUM_BITS-1:0] data_in_ext;
    assign data_in_ext = $signed(data_in);

    // =========================================================================
    // 1. INTEGRATOR SECTION (High Rate @ 2.4 GSps)
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < STAGES; k++) begin
                int_reg[k] <= '0;
            end
        end else if (valid_in) begin
            int_reg[0] <= int_reg[0] + data_in_ext;
            for (int k = 1; k < STAGES; k++) begin
                int_reg[k] <= int_reg[k] + int_reg[k-1];
            end
        end
    end

    // =========================================================================
    // 2. DECIMATION RATE COUNTER
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rate_cnt     <= '0;
            decim_strobe <= 1'b0;
        end else if (valid_in) begin
            if (rate_cnt == decim_rate - 1'b1) begin
                rate_cnt     <= '0;
                decim_strobe <= 1'b1;
            end else begin
                rate_cnt     <= rate_cnt + 1'b1;
                decim_strobe <= 1'b0;
            end
        end else begin
            decim_strobe <= 1'b0;
        end
    end

    // =========================================================================
    // 3. COMB SECTION (Low Rate @ 2.4 / R GSps)
    // =========================================================================
    logic signed [ACCUM_BITS-1:0] comb_in;
    assign comb_in = int_reg[STAGES-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < STAGES; k++) begin
                comb_reg[k]   <= '0;
                comb_delay[k] <= '0;
            end
            valid_out <= 1'b0;
            data_out  <= '0;
        end else if (decim_strobe) begin
            // Comb Stage 0
            comb_delay[0] <= comb_in;
            comb_reg[0]   <= comb_in - comb_delay[0];

            // Cascaded Comb Stages 1 to N-1
            for (int k = 1; k < STAGES; k++) begin
                comb_delay[k] <= comb_reg[k-1];
                comb_reg[k]   <= comb_reg[k-1] - comb_delay[k];
            end

            // Output Scaling & Bit Pruning
            data_out  <= comb_reg[STAGES-1] >>> SHIFT_BITS;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // 4. INLINE SYSTEMVERILOG ASSERTIONS (SVA - Verification & Formal Checks)
    // =========================================================================
    `ifndef SYNTHESIS
    // Assert rate counter stays bounded
    property p_rate_counter_bound;
        @(posedge clk) disable iff (!rst_n)
        valid_in |-> (rate_cnt < decim_rate);
    endproperty
    assert_rate_counter_bound: assert property (p_rate_counter_bound);

    // Assert valid_out fires only on decim_strobe
    property p_valid_out_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> $past(decim_strobe);
    endproperty
    assert_valid_out_sync: assert property (p_valid_out_sync);
    `endif

endmodule
