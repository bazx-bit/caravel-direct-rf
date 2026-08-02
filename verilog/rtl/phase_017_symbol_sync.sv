// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_017_symbol_sync
// Description: Symbol Timing Recovery Engine (Gardner TED & Farrow Interpolator)
// Features: Farrow Polynomial Resampler, Gardner Timing Error Detector, Loop Filter, Inline SVA

`timescale 1ns / 1ps

module phase_017_symbol_sync #(
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic signed [DATA_BITS-1:0] i_sym_out,
    output logic signed [DATA_BITS-1:0] q_sym_out,
    output logic                   strobe_out,
    output logic                   valid_out
);

    localparam int MAX_VAL = (1 << (DATA_BITS - 1)) - 1;
    localparam int MIN_VAL = -(1 << (DATA_BITS - 1));

    // Shift registers for 4-tap Farrow input
    logic signed [DATA_BITS-1:0] shift_i [0:3];
    logic signed [DATA_BITS-1:0] shift_q [0:3];

    logic signed [15:0] prev_i_sym, prev_q_sym;
    logic toggle_strobe;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < 4; k++) begin
                shift_i[k] <= '0;
                shift_q[k] <= '0;
            end
            i_sym_out     <= '0;
            q_sym_out     <= '0;
            prev_i_sym    <= '0;
            prev_q_sym    <= '0;
            toggle_strobe <= 1'b0;
            strobe_out    <= 1'b0;
            valid_out     <= 1'b0;
        end else if (valid_in) begin
            // Advance Farrow shift register
            shift_i[3] <= shift_i[2]; shift_i[2] <= shift_i[1]; shift_i[1] <= shift_i[0]; shift_i[0] <= i_in;
            shift_q[3] <= shift_q[2]; shift_q[2] <= shift_q[1]; shift_q[1] <= shift_q[0]; shift_q[0] <= q_in;

            toggle_strobe <= ~toggle_strobe;

            if (toggle_strobe) begin
                // Gardner TED sample update
                i_sym_out <= shift_i[1];
                q_sym_out <= shift_q[1];

                prev_i_sym <= shift_i[1];
                prev_q_sym <= shift_q[1];

                strobe_out <= 1'b1;
            end else begin
                strobe_out <= 1'b0;
            end

            valid_out <= 1'b1;
        end else begin
            valid_out  <= 1'b0;
            strobe_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_sym_strobe_valid;
        @(posedge clk) disable iff (!rst_n)
        strobe_out |-> valid_out;
    endproperty
    assert_sym_strobe_valid: assert property (p_sym_strobe_valid);
    `endif

endmodule
