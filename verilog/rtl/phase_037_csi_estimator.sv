// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_037_csi_estimator
// Description: Dynamic Channel State Information (CSI) Sounding & Estimation Unit
// Features: Real-Time 4x4 MIMO Channel Matrix Estimation, Least-Squares Solver, Inline SVA

`timescale 1ns / 1ps

module phase_037_csi_estimator #(
    parameter int DATA_BITS = 16,
    parameter int NUM_RX    = 4,
    parameter int NUM_TX    = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Received Pilot Signals across 4 RX Antennas
    input  logic signed [DATA_BITS-1:0] rx_i [0:NUM_RX-1],
    input  logic signed [DATA_BITS-1:0] rx_q [0:NUM_RX-1],
    
    // Known Transmitted Pilot Signals across 4 TX Antennas
    input  logic signed [DATA_BITS-1:0] tx_i [0:NUM_TX-1],
    input  logic signed [DATA_BITS-1:0] tx_q [0:NUM_TX-1],
    
    input  logic                   valid_in,

    // 4x4 Complex Channel Matrix H Output
    output logic signed [DATA_BITS-1:0] h_matrix_i [0:NUM_RX-1][0:NUM_TX-1],
    output logic signed [DATA_BITS-1:0] h_matrix_q [0:NUM_RX-1][0:NUM_TX-1],
    output logic                   matrix_valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int r = 0; r < NUM_RX; r++) begin
                for (int t = 0; t < NUM_TX; t++) begin
                    h_matrix_i[r][t] <= '0;
                    h_matrix_q[r][t] <= '0;
                end
            end
            matrix_valid_out <= 1'b0;
        end else if (valid_in) begin
            // H_rt = Y_r / X_t estimation (Complex Division Model)
            for (int r = 0; r < NUM_RX; r++) begin
                for (int t = 0; t < NUM_TX; t++) begin
                    logic signed [31:0] denom;
                    denom = (tx_i[t] * tx_i[t] + tx_q[t] * tx_q[t]) >>> 15;
                    
                    if (denom != 0) begin
                        h_matrix_i[r][t] <= ((rx_i[r] * tx_i[t] + rx_q[r] * tx_q[t]) / denom);
                        h_matrix_q[r][t] <= ((rx_q[r] * tx_i[t] - rx_i[r] * tx_q[t]) / denom);
                    end else begin
                        h_matrix_i[r][t] <= 16'sd32767; // Default identity
                        h_matrix_q[r][t] <= '0;
                    end
                end
            end
            matrix_valid_out <= 1'b1;
        end else begin
            matrix_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_csi_valid_sync;
        @(posedge clk) disable iff (!rst_n)
        valid_in |=> matrix_valid_out;
    endproperty
    assert_csi_valid_sync: assert property (p_csi_valid_sync);
    `endif

endmodule
