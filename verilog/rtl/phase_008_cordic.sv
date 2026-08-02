// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_008_cordic
// Description: 16-Stage Pipelined CORDIC Vectoring Unit for Phase & Frequency Demodulation
// Features: Quadrant Alignment, 16-Stage Shift-and-Add Pipeline, Inverse-Gain Multiplier, Inline SVA

`timescale 1ns / 1ps

module phase_008_cordic #(
    parameter int STAGES    = 16,
    parameter int DATA_BITS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] i_in,
    input  logic signed [DATA_BITS-1:0] q_in,
    input  logic                   valid_in,
    output logic signed [DATA_BITS-1:0] magnitude_out,
    output logic signed [DATA_BITS-1:0] phase_out,
    output logic signed [DATA_BITS-1:0] freq_out,
    output logic                   valid_out
);

    localparam int CORDIC_GAIN_INV_Q15 = 19898; // 0.607252935 * 32768

    // Arctan ROM Table (Q1.15 fixed point format: pi mapped to 32767)
    logic signed [DATA_BITS-1:0] atan_rom [0:STAGES-1];

    initial begin
        atan_rom[0]  = 16'sd8192;  atan_rom[1]  = 16'sd4836;  atan_rom[2]  = 16'sd2555;  atan_rom[3]  = 16'sd1297;
        atan_rom[4]  = 16'sd651;   atan_rom[5]  = 16'sd326;   atan_rom[6]  = 16'sd163;   atan_rom[7]  = 16'sd81;
        atan_rom[8]  = 16'sd41;    atan_rom[9]  = 16'sd20;    atan_rom[10] = 16'sd10;    atan_rom[11] = 16'sd5;
        atan_rom[12] = 16'sd3;     atan_rom[13] = 16'sd1;     atan_rom[14] = 16'sd1;     atan_rom[15] = 16'sd0;
    end

    // Pipeline Registers
    logic signed [DATA_BITS:0] x_pipe [0:STAGES];
    logic signed [DATA_BITS:0] y_pipe [0:STAGES];
    logic signed [DATA_BITS-1:0] z_pipe [0:STAGES];
    logic valid_pipe [0:STAGES];

    // 1. Quadrant Alignment Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_pipe[0]     <= '0;
            y_pipe[0]     <= '0;
            z_pipe[0]     <= '0;
            valid_pipe[0] <= 1'b0;
        end else if (valid_in) begin
            if (i_in < 0) begin
                if (q_in >= 0) begin
                    x_pipe[0] <= $signed(q_in);
                    y_pipe[0] <= -$signed(i_in);
                    z_pipe[0] <= 16'sd16384; // +pi/2
                end else begin
                    x_pipe[0] <= -$signed(q_in);
                    y_pipe[0] <= $signed(i_in);
                    z_pipe[0] <= -16'sd16384; // -pi/2
                end
            end else begin
                x_pipe[0] <= $signed(i_in);
                y_pipe[0] <= $signed(q_in);
                z_pipe[0] <= 16'sd0;
            end
            valid_pipe[0] <= 1'b1;
        end else begin
            valid_pipe[0] <= 1'b0;
        end
    end

    // 2. 16-Stage Shift-and-Add CORDIC Vectoring Pipeline
    generate
        for (genvar i = 0; i < STAGES; i++) begin : g_cordic_stages
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x_pipe[i+1]     <= '0;
                    y_pipe[i+1]     <= '0;
                    z_pipe[i+1]     <= '0;
                    valid_pipe[i+1] <= 1'b0;
                end else begin
                    logic d;
                    d = y_pipe[i] < 0 ? 1'b1 : 1'b0;

                    if (d) begin
                        x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] - atan_rom[i];
                    end else begin
                        x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] + atan_rom[i];
                    end
                    valid_pipe[i+1] <= valid_pipe[i];
                end
            end
        end
    endgenerate

    // 3. Gain Compensation & Frequency Differentiator Output Stage
    logic signed [31:0] mag_scaled_full;
    logic signed [DATA_BITS-1:0] prev_phase_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mag_scaled_full <= '0;
            magnitude_out   <= '0;
            phase_out       <= '0;
            freq_out        <= '0;
            prev_phase_reg  <= '0;
            valid_out       <= 1'b0;
        end else if (valid_pipe[STAGES]) begin
            // Inverse Gain Compensation: Magnitude = x * 0.60725
            mag_scaled_full <= (x_pipe[STAGES] * CORDIC_GAIN_INV_Q15) >>> 15;
            magnitude_out   <= mag_scaled_full[DATA_BITS-1:0];

            phase_out       <= z_pipe[STAGES];

            // FM Frequency Demodulator: dtheta/dt = phase[n] - phase[n-1]
            freq_out        <= z_pipe[STAGES] - prev_phase_reg;
            prev_phase_reg  <= z_pipe[STAGES];

            valid_out       <= 1'b1;
        end else begin
            valid_out       <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_cordic_valid_delay;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> $past(valid_in, STAGES + 1);
    endproperty
    assert_cordic_valid_delay: assert property (p_cordic_valid_delay);
    `endif

endmodule
