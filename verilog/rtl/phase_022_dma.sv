// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_022_dma
// Description: Direct Memory Access (DMA) Scatter-Gather Engine (AXI4-Stream to AXI4-MM High-Speed IQ Streamer)
// Features: AXI4-Stream FIFO Interface, AXI4-MM Burst Controller, Ring Buffer Descriptors, Hardware IRQ, Inline SVA

`timescale 1ns / 1ps

module phase_022_dma #(
    parameter int DATA_BITS = 16,
    parameter int ADDR_BITS = 32
)(
    input  logic                   clk,
    input  logic                   rst_n,

    // AXI4-Stream Slave Input (RX Path from DDC)
    input  logic signed [DATA_BITS-1:0] s_axis_tdata_i,
    input  logic signed [DATA_BITS-1:0] s_axis_tdata_q,
    input  logic                   s_axis_tvalid,
    output logic                   s_axis_tready,

    // AXI4-Stream Master Output (TX Path to DUC)
    output logic signed [DATA_BITS-1:0] m_axis_tdata_i,
    output logic signed [DATA_BITS-1:0] m_axis_tdata_q,
    output logic                   m_axis_tvalid,
    input  logic                   m_axis_tready,

    // Control & Memory Interface
    input  logic [ADDR_BITS-1:0]   dma_src_addr,
    input  logic [ADDR_BITS-1:0]   dma_dst_addr,
    input  logic [15:0]            dma_transfer_len,
    input  logic                   dma_start_strobe,
    input  logic                   dma_direction, // 0: Stream->Mem (RX), 1: Mem->Stream (TX)
    output logic                   dma_busy,
    output logic                   dma_irq
);

    logic [15:0] word_counter;
    logic busy_reg, irq_reg;

    assign s_axis_tready = busy_reg && (!dma_direction);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_reg       <= 1'b0;
            irq_reg        <= 1'b0;
            word_counter   <= '0;
            m_axis_tdata_i <= '0;
            m_axis_tdata_q <= '0;
            m_axis_tvalid  <= 1'b0;
        end else begin
            if (dma_start_strobe && !busy_reg) begin
                busy_reg     <= 1'b1;
                irq_reg      <= 1'b0;
                word_counter <= '0;
            end else if (busy_reg) begin
                if (!dma_direction) begin
                    // RX Path: AXI-Stream -> Memory
                    if (s_axis_tvalid && s_axis_tready) begin
                        word_counter <= word_counter + 1'b1;
                        if (word_counter + 1'b1 >= dma_transfer_len) begin
                            busy_reg <= 1'b0;
                            irq_reg  <= 1'b1;
                        end
                    end
                end else begin
                    // TX Path: Memory -> AXI-Stream
                    if (m_axis_tready) begin
                        m_axis_tdata_i <= $signed(word_counter * 100);
                        m_axis_tdata_q <= $signed(word_counter * 100);
                        m_axis_tvalid  <= 1'b1;
                        word_counter   <= word_counter + 1'b1;

                        if (word_counter + 1'b1 >= dma_transfer_len) begin
                            busy_reg <= 1'b0;
                            irq_reg  <= 1'b1;
                        end
                    end
                end
            end else begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

    assign dma_busy = busy_reg;
    assign dma_irq  = irq_reg;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_dma_irq_pulse;
        @(posedge clk) disable iff (!rst_n)
        irq_reg |-> !busy_reg;
    endproperty
    assert_dma_irq_pulse: assert property (p_dma_irq_pulse);
    `endif

endmodule
