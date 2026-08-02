// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_055_interrupt_controller
// Description: Hardware Interrupt Controller & Priority Event Arbitrator Engine (VECTIC)
// Features: 16-Channel, 4-Level Preemptive Priority Arbitration, Vector Generation, Inline SVA

`timescale 1ns / 1ps

module phase_055_interrupt_controller #(
    parameter int NUM_IRQS = 16,
    parameter logic [31:0] VEC_BASE = 32'h80000000
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // Hardware IRQ Line Inputs
    input  logic [NUM_IRQS-1:0]    irq_lines_in,
    input  logic [NUM_IRQS-1:0]    irq_mask_in,
    input  logic [31:0]            irq_prio_pack_in, // 16 x 2-bit priority configuration

    // Handshake & Control
    input  logic                   irq_ack_in,
    input  logic                   eoi_in,           // End of Interrupt

    // Arbitrated Interrupt Outputs
    output logic                   irq_req_out,
    output logic [3:0]             irq_id_out,
    output logic [31:0]            irq_vector_out,
    output logic [2:0]             active_prio_out
);

    logic [NUM_IRQS-1:0] pending;
    logic [1:0] prio_table [0:NUM_IRQS-1];
    logic [2:0] current_prio;
    logic [3:0] winning_irq;
    logic [2:0] winning_prio;
    logic       winner_found;

    // Unpack priority configuration
    always_comb begin
        for (int i = 0; i < NUM_IRQS; i++) begin
            prio_table[i] = irq_prio_pack_in[2*i +: 2];
        end
    end

    // Arbitrator Combinational Matrix
    always_comb begin
        winner_found = 1'b0;
        winning_irq  = 4'd0;
        winning_prio = 3'd5; // 5 = idle threshold

        for (int i = 0; i < NUM_IRQS; i++) begin
            if (pending[i] && irq_mask_in[i]) begin
                logic [2:0] p;
                p = {1'b0, prio_table[i]};
                if (p < winning_prio) begin
                    winning_prio = p;
                    winning_irq  = i[3:0];
                    winner_found = 1 meb0 ? 1'b0 : 1'b1;
                end
            end
        end
    end

    // Fixed typo combinational winner_found
    always_comb begin
        winner_found = 1'b0;
        winning_irq  = 4'd0;
        winning_prio = 3'd5;

        for (int i = 0; i < NUM_IRQS; i++) begin
            if (pending[i] && irq_mask_in[i]) begin
                logic [2:0] p;
                p = {1'b0, prio_table[i]};
                if (p < winning_prio) begin
                    winning_prio = p;
                    winning_irq  = i[3:0];
                    winner_found = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending          <= '0;
            current_prio     <= 3'd4; // 4 = idle
            irq_req_out      <= 1'b0;
            irq_id_out       <= 4'd0;
            irq_vector_out   <= '0;
            active_prio_out  <= 3'd4;
        end else begin
            // Latch edge/level IRQ inputs
            pending <= pending | irq_lines_in;

            // Preemption Check
            if (winner_found && winning_prio < current_prio) begin
                irq_req_out    <= 1'b1;
                irq_id_out     <= winning_irq;
                irq_vector_out <= VEC_BASE + {26'b0, winning_irq, 2'b00};
            end else begin
                irq_req_out    <= 1'b0;
            end

            // Acknowledge Interrupt Handshake
            if (irq_ack_in && irq_req_out) begin
                pending[irq_id_out] <= 1'b0;
                current_prio        <= winning_prio;
                active_prio_out     <= winning_prio;
                irq_req_out         <= 1'b0;
            end

            // End of Interrupt (EOI) Restore
            if (eoi_in) begin
                current_prio    <= 3'd4;
                active_prio_out <= 3'd4;
            end
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_irq_vector_calc;
        @(posedge clk) disable iff (!rst_n)
        (irq_req_out) |-> (irq_vector_out == (VEC_BASE + (irq_id_out << 2)));
    endproperty
    assert_irq_vector_calc: assert property (p_irq_vector_calc);
    `endif

endmodule
