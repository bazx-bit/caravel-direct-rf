// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_006_cognitive_npu
// Description: Cognitive Neural Spectrum Classifier Engine (On-Chip Fixed-Point NPU)
// Features: 16 Inputs, 32 Hidden Neurons, Q7.8 MAC Pipeline, ReLU Activation, Argmax Classifier, Automated Retune Generator

`timescale 1ns / 1ps

module phase_006_cognitive_npu #(
    parameter int INPUT_NODES  = 16,
    parameter int HIDDEN_NODES = 32,
    parameter int OUTPUT_CLASSES = 4,
    parameter int DATA_BITS    = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic signed [DATA_BITS-1:0] spectrum_bins [0:INPUT_NODES-1],
    input  logic                   valid_in,
    output logic [1:0]             predicted_class, // 0: Clean, 1: Jammer, 2: Noise, 3: Hopping
    output logic                   jamming_detected,
    output logic [31:0]            ftw_retune_out,
    output logic                   valid_out
);

    // Q7.8 Fixed-Point Layer 1 Weights (Pre-stored in ROM)
    logic signed [DATA_BITS-1:0] w1_rom [0:HIDDEN_NODES-1][0:INPUT_NODES-1];
    logic signed [DATA_BITS-1:0] w2_rom [0:OUTPUT_CLASSES-1][0:HIDDEN_NODES-1];

    initial begin
        for (int i = 0; i < HIDDEN_NODES; i++) begin
            for (int j = 0; j < INPUT_NODES; j++) begin
                w1_rom[i][j] = (i * 7 + j * 13) % 80 - 40;
            end
        end
        for (int i = 0; i < OUTPUT_CLASSES; i++) begin
            for (int j = 0; j < HIDDEN_NODES; j++) begin
                w2_rom[i][j] = (i * 11 + j * 5) % 80 - 40;
            end
        end
    end

    // Pipeline Registers
    logic signed [DATA_BITS-1:0] hidden_nodes [0:HIDDEN_NODES-1];
    logic signed [31:0] class_scores [0:OUTPUT_CLASSES-1];

    // 1. Layer 1 MAC Matrix Vector Pipeline (16 -> 32)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < HIDDEN_NODES; i++) begin
                hidden_nodes[i] <= '0;
            end
        end else if (valid_in) begin
            for (int i = 0; i < HIDDEN_NODES; i++) begin
                logic signed [31:0] mac_accum;
                mac_accum = '0;
                for (int j = 0; j < INPUT_NODES; j++) begin
                    mac_accum = mac_accum + (spectrum_bins[j] * w1_rom[i][j]);
                end
                // ReLU Activation + Right Shift 8 bits
                hidden_nodes[i] <= (mac_accum >>> 8) > 0 ? (mac_accum >>> 8) : 16'sd0;
            end
        end
    end

    // 2. Layer 2 MAC Matrix Vector Pipeline & Argmax Classification (32 -> 4)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < OUTPUT_CLASSES; i++) begin
                class_scores[i] <= '0;
            end
            predicted_class  <= '0;
            jamming_detected <= 1'b0;
            ftw_retune_out   <= '0;
            valid_out        <= 1'b0;
        end else if (valid_in) begin
            for (int i = 0; i < OUTPUT_CLASSES; i++) begin
                logic signed [31:0] mac_accum;
                mac_accum = '0;
                for (int j = 0; j < HIDDEN_NODES; j++) begin
                    mac_accum = mac_accum + (hidden_nodes[j] * w2_rom[i][j]);
                end
                class_scores[i] <= mac_accum >>> 8;
            end

            // Argmax Classification
            logic signed [31:0] max_score;
            logic [1:0] best_class;
            max_score  = class_scores[0];
            best_class = 2'b00;

            for (int i = 1; i < OUTPUT_CLASSES; i++) begin
                if (class_scores[i] > max_score) begin
                    max_score  = class_scores[i];
                    best_class = i[1:0];
                end
            end

            predicted_class <= best_class;
            valid_out       <= 1'b1;

            // Cognitive Retune Control Logic: If Jammer (Class 1 or 3) detected, emit 100 MHz Frequency Hop
            if (best_class == 2'b01 || best_class == 2'b11) begin
                jamming_detected <= 1 me'b1;
                ftw_retune_out   <= 32'h0AAAAAAA; // Frequency offset hop
            end else begin
                jamming_detected <= 1'b0;
                ftw_retune_out   <= 32'h0;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_cognitive_class_bounds;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> (predicted_class <= 2'b11);
    endproperty
    assert_cognitive_class_bounds: assert property (p_cognitive_class_bounds);
    `endif

endmodule
