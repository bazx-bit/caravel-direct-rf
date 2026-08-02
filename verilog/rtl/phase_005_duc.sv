// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_005_duc
// Description: Top-Level Digital Up-Converter (DUC) Pipeline (TX Path)
// Features: NCO Integration, Dual CIC Interpolators (R=16), Quadrature Modulator, Inline SVA Assertions

`timescale 1ns / 1ps

module phase_005_duc #(
    parameter int ACCUM_BITS  = 32,
    parameter int INPUT_BITS  = 16,
    parameter int OUTPUT_BITS = 16,
    parameter int STAGES      = 5
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [ACCUM_BITS-1:0]  ftw,
    input  logic [ACCUM_BITS-1:0]  phase_offset,
    input  logic [5:0]             interp_rate, // R = 16
    input  logic signed [INPUT_BITS-1:0] i_baseband_in,
    input  logic signed [INPUT_BITS-1:0] q_baseband_in,
    input  logic                   valid_in,
    output logic signed [OUTPUT_BITS-1:0] rf_data_out,
    output logic                   valid_out
);

    localparam int CIC_ACCUM_BITS = 46;
    localparam int MAX_VAL        = (1 << (OUTPUT_BITS - 1)) - 1;
    localparam int MIN_VAL        = -(1 << (OUTPUT_BITS - 1));

    // NCO Local Carrier Signals
    logic signed [INPUT_BITS-1:0] i_nco, q_nco;
    logic nco_valid;

    // Instantiate Phase 001 NCO
    phase_001_dds #(
        .ACCUM_BITS(ACCUM_BITS),
        .LUT_BITS(14),
        .OUTPUT_BITS(INPUT_BITS)
    ) u_dds_tx (
        .clk(clk),
        .rst_n(rst_n),
        .ftw(ftw),
        .phase_offset(phase_offset),
        .i_out(i_nco),
        .q_out(q_nco),
        .valid_out(nco_valid)
    );

    // =========================================================================
    // CIC INTERPOLATOR COMB SECTION (Low Rate Baseband)
    // =========================================================================
    logic signed [CIC_ACCUM_BITS-1:0] comb_reg_i [0:STAGES-1];
    logic signed [CIC_ACCUM_BITS-1:0] comb_delay_i [0:STAGES-1];
    logic signed [CIC_ACCUM_BITS-1:0] comb_reg_q [0:STAGES-1];
    logic signed [CIC_ACCUM_BITS-1:0] comb_delay_q [0:STAGES-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < STAGES; k++) begin
                comb_reg_i[k]   <= '0; comb_delay_i[k] <= '0;
                comb_reg_q[k]   <= '0; comb_delay_q[k] <= '0;
            end
        end else if (valid_in) begin
            // I Channel Comb Pipeline
            comb_delay_i[0] <= $signed(i_baseband_in);
            comb_reg_i[0]   <= $signed(i_baseband_in) - comb_delay_i[0];
            for (int k = 1; k < STAGES; k++) begin
                comb_delay_i[k] <= comb_reg_i[k-1];
                comb_reg_i[k]   <= comb_reg_i[k-1] - comb_delay_i[k];
            end

            // Q Channel Comb Pipeline
            comb_delay_q[0] <= $signed(q_baseband_in);
            comb_reg_q[0]   <= $signed(q_baseband_in) - comb_delay_q[0];
            for (int k = 1; k < STAGES; k++) begin
                comb_delay_q[k] <= comb_reg_q[k-1];
                comb_reg_q[k]   <= comb_reg_q[k-1] - comb_delay_q[k];
            end
        end
    end

    // =========================================================================
    // CIC INTERPOLATOR INTEGRATOR SECTION (High Rate @ 2.4 GSps)
    // =========================================================================
    logic signed [CIC_ACCUM_BITS-1:0] int_reg_i [0:STAGES-1];
    logic signed [CIC_ACCUM_BITS-1:0] int_reg_q [0:STAGES-1];

    logic signed [INPUT_BITS-1:0] i_up_scaled, q_up_scaled;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < STAGES; k++) begin
                int_reg_i[k] <= '0;
                int_reg_q[k] <= '0;
            end
            i_up_scaled <= '0;
            q_up_scaled <= '0;
        end else begin
            // Zero insertion: feed comb_reg output on valid_in, zero otherwise
            logic signed [CIC_ACCUM_BITS-1:0] feed_i, feed_q;
            feed_i = valid_in ? comb_reg_i[STAGES-1] : '0;
            feed_q = valid_in ? comb_reg_q[STAGES-1] : '0;

            int_reg_i[0] <= int_reg_i[0] + feed_i;
            int_reg_q[0] <= int_reg_q[0] + feed_q;

            for (int k = 1; k < STAGES; k++) begin
                int_reg_i[k] <= int_reg_i[k] + int_reg_i[k-1];
                int_reg_q[k] <= int_reg_q[k] + int_reg_q[k-1];
            end

            // Right-shift by 16 bits gain scaling
            i_up_scaled <= int_reg_i[STAGES-1] >>> 16;
            q_up_scaled <= int_reg_q[STAGES-1] >>> 16;
        end
    end

    // =========================================================================
    // QUADRATURE MODULATOR: RF(t) = I(t)*cos(w0*t) - Q(t)*sin(w0*t)
    // =========================================================================
    logic signed [31:0] mult_i, mult_q;
    logic signed [31:0] rf_sum;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_i      <= '0;
            mult_q      <= '0;
            rf_sum      <= '0;
            rf_data_out <= '0;
            valid_out   <= 1'b0;
        end else begin
            mult_i <= i_up_scaled * i_nco;
            mult_q <= q_up_scaled * q_nco;

            // Q1.15 modulation sum & right shift
            rf_sum <= (mult_i >>> 15) - (mult_q >>> 15);

            // Saturation clipping to 16-bit signed range
            rf_data_out <= rf_sum > MAX_VAL ? MAX_VAL[OUTPUT_BITS-1:0] :
                          (rf_sum < MIN_VAL ? MIN_VAL[OUTPUT_BITS-1:0] : rf_sum[OUTPUT_BITS-1:0]);
            valid_out   <= nco_valid;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_duc_valid_out;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> nco_valid;
    endproperty
    assert_duc_valid_out: assert property (p_duc_valid_out);
    `endif

endmodule
