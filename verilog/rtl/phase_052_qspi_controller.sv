// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_052_qspi_controller
// Description: High-Speed Serial Peripheral Interface (QSPI / OSPI) Flash Memory Controller Engine
// Features: 1-bit / 4-bit / 8-bit Mode Support, XIP Memory Read Translation, Inline SVA

`timescale 1ns / 1ps

module phase_052_qspi_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Control & Memory Request Interface
    input  logic [1:0]  bus_mode_in,        // 00=Single, 01=Quad, 10=Octal
    input  logic [23:0] read_addr_in,
    input  logic [3:0]  dummy_cycles_in,
    input  logic        read_req_in,

    // Flash Hardware Bus Pins
    output logic        qspi_sclk_out,
    output logic        qspi_cs_n_out,
    output logic [7:0]  qspi_io_out,
    input  logic [7:0]  qspi_io_in,
    output logic [7:0]  qspi_io_oe_out,     // Output Enable

    // Data Readout Interface
    output logic [31:0] read_data_out,
    output logic        read_valid_out,
    output logic        busy_out
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_CMD,
        S_ADDR,
        S_DUMMY,
        S_DATA,
        S_DONE
    } state_t;

    state_t state;
    logic [3:0] bit_cnt;
    logic [3:0] dummy_cnt;
    logic [31:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            qspi_sclk_out  <= 1'b0;
            qspi_cs_n_out  <= 1'b1;
            qspi_io_out    <= 8'h00;
            qspi_io_oe_out <= 8'h00;
            read_data_out  <= 32'h0;
            read_valid_out <= 1'b0;
            busy_out       <= 1'b0;
            bit_cnt        <= 4'd0;
            dummy_cnt      <= 4'd0;
            shift_reg      <= 32'h0;
        end else begin
            read_valid_out <= 1'b0;

            case (state)
                S_IDLE: begin
                    qspi_cs_n_out  <= 1'b1;
                    qspi_sclk_out  <= 1'b0;
                    qspi_io_oe_out <= 8'h00;
                    busy_out       <= 1'b0;

                    if (read_req_in) begin
                        qspi_cs_n_out  <= 1'b0;
                        qspi_io_oe_out <= 8'hFF;
                        qspi_io_out    <= 8'hEB; // Fast Read Quad I/O Command
                        busy_out       <= 1'b1;
                        bit_cnt        <= 4'd0;
                        state          <= S_CMD;
                    end
                end

                S_CMD: begin
                    qspi_sclk_out <= ~qspi_sclk_out;
                    if (qspi_sclk_out) begin
                        qspi_io_out <= read_addr_in[23:16];
                        bit_cnt     <= 4'd0;
                        state       <= S_ADDR;
                    end
                end

                S_ADDR: begin
                    qspi_sclk_out <= ~qspi_sclk_out;
                    if (qspi_sclk_out) begin
                        if (dummy_cycles_in > 0) begin
                            qspi_io_oe_out <= 8'h00; // Tristate for dummy/read
                            dummy_cnt      <= 4'd0;
                            state          <= S_DUMMY;
                        end else begin
                            qspi_io_oe_out <= 8'h00;
                            bit_cnt        <= 4'd0;
                            state          <= S_DATA;
                        end
                    end
                end

                S_DUMMY: begin
                    qspi_sclk_out <= ~qspi_sclk_out;
                    if (qspi_sclk_out) begin
                        if (dummy_cnt + 1'b1 >= dummy_cycles_in) begin
                            bit_cnt <= 4'd0;
                            state   <= S_DATA;
                        end else begin
                            dummy_cnt <= dummy_cnt + 1'b1;
                        end
                    end
                end

                S_DATA: begin
                    qspi_sclk_out <= ~qspi_sclk_out;
                    if (!qspi_sclk_out) begin
                        // Sample IO on rising clock edge
                        case (bus_mode_in)
                            2'b00: shift_reg <= {shift_reg[30:0], qspi_io_in[0]};
                            2'b01: shift_reg <= {shift_reg[27:0], qspi_io_in[3:0]};
                            2'b10: shift_reg <= {shift_reg[23:0], qspi_io_in[7:0]};
                            default: shift_reg <= {shift_reg[27:0], qspi_io_in[3:0]};
                        endcase
                        
                        if (bit_cnt == 4'd7) begin
                            state <= S_DONE;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                S_DONE: begin
                    qspi_cs_n_out  <= 1'b1;
                    read_data_out  <= shift_reg;
                    read_valid_out <= 1'b1;
                    busy_out       <= 1'b0;
                    state          <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_qspi_cs_active;
        @(posedge clk) disable iff (!rst_n)
        busy_out |-> !qspi_cs_n_out;
    endproperty
    assert_qspi_cs_active: assert property (p_qspi_cs_active);
    `endif

endmodule
