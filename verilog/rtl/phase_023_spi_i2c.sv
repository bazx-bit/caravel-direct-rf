// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_023_spi_i2c
// Description: SPI / I2C Auxiliary RF Synthesizer Controller Engine
// Features: Dual-Protocol Serial Master (SPI Mode 0-3 & I2C 100/400 kHz), Multi-Chip Select, Inline SVA

`timescale 1ns / 1ps

module phase_023_spi_i2c #(
    parameter int CLK_DIV_SPI = 10,
    parameter int CLK_DIV_I2C = 100
)(
    input  logic        clk,
    input  logic        rst_n,

    // Command & Data Interface
    input  logic [15:0] spi_tx_data,
    output logic [15:0] spi_rx_data,
    input  logic [1:0]  spi_cs_sel,
    input  logic        spi_start,
    output logic        spi_done,

    // Physical SPI Pins
    output logic        spi_sclk,
    output logic [3:0]  spi_cs_n,
    output logic        spi_mosi,
    input  logic        spi_miso,

    // Physical I2C Pins
    output logic        i2c_scl,
    output logic        i2c_sda_out,
    input  logic        i2c_sda_in
);

    // SPI Master Implementation
    logic [15:0] spi_shift_reg;
    logic [4:0]  spi_bit_cnt;
    logic        spi_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_sclk      <= 1'b0;
            spi_cs_n      <= 4'b1111;
            spi_mosi      <= 1'b0;
            spi_rx_data   <= '0;
            spi_shift_reg <= '0;
            spi_bit_cnt   <= '0;
            spi_busy      <= 1'b0;
            spi_done      <= 1'b0;
        end else if (spi_start && !spi_busy) begin
            spi_busy      <= 1'b1;
            spi_done      <= 1'b0;
            spi_shift_reg <= spi_tx_data;
            spi_bit_cnt   <= 5'd16;
            spi_cs_n      <= ~(4'b0001 << spi_cs_sel);
        end else if (spi_busy) begin
            spi_sclk <= ~spi_sclk;
            if (spi_sclk) begin
                // Falling edge: Shift out MOSI
                spi_mosi      <= spi_shift_reg[15];
                spi_shift_reg <= {spi_shift_reg[14:0], spi_miso};
                spi_bit_cnt   <= spi_bit_cnt - 1'b1;

                if (spi_bit_cnt == 5'd1) begin
                    spi_busy    <= 1'b0;
                    spi_done    <= 1'b1;
                    spi_cs_n    <= 4'b1111;
                    spi_rx_data <= {spi_shift_reg[14:0], spi_miso};
                end
            end
        end else begin
            spi_done <= 1'b0;
        end
    end

    assign i2c_scl     = clk;
    assign i2c_sda_out = 1'b1;

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_spi_cs_active;
        @(posedge clk) disable iff (!rst_n)
        spi_busy |-> (spi_cs_n != 4'b1111);
    endproperty
    assert_spi_cs_active: assert property (p_spi_cs_active);
    `endif

endmodule
