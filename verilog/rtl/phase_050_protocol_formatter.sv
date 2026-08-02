// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_050_protocol_formatter
// Description: Multi-Standard Wireless Protocol Codec & Frame Formatter Engine
// Features: 5G NR / Wi-Fi 6 / LoRa / BT5.x Frame Builder, CRC-8 Appender, Inline SVA

`timescale 1ns / 1ps

module phase_050_protocol_formatter #(
    parameter int MAX_PAYLOAD = 256
)(
    input  logic        clk,
    input  logic        rst_n,

    // Frame Build Controls
    input  logic [1:0]  protocol_id_in,     // 00=5G_NR, 01=WiFi6, 10=LoRa, 11=BT5
    input  logic [15:0] dest_addr_in,
    input  logic [15:0] src_addr_in,
    input  logic [7:0]  channel_id_in,
    input  logic [7:0]  payload_len_in,
    input  logic [7:0]  payload_byte_in,
    input  logic        payload_valid_in,
    input  logic        frame_start_in,

    // Frame Output
    output logic [7:0]  frame_byte_out,
    output logic        frame_valid_out,
    output logic        frame_last_out,
    output logic [7:0]  crc8_out
);

    // Sync word LUT per protocol
    logic [15:0] sync_words [0:3];
    assign sync_words[0] = 16'h5AA5;  // 5G NR
    assign sync_words[1] = 16'hAA55;  // Wi-Fi 6
    assign sync_words[2] = 16'hC0DE;  // LoRa
    assign sync_words[3] = 16'hBEEF;  // Bluetooth 5.x

    // Header buffer (10 bytes)
    logic [7:0] header [0:9];

    // State machine
    typedef enum logic [2:0] {
        S_IDLE,
        S_BUILD_HEADER,
        S_EMIT_HEADER,
        S_EMIT_PAYLOAD,
        S_EMIT_CRC
    } state_t;

    state_t state;
    logic [3:0] hdr_idx;
    logic [7:0] pay_cnt;
    logic [7:0] crc_reg;

    // CRC-8 polynomial 0x07
    function automatic logic [7:0] crc8_update(input logic [7:0] crc_in, input logic [7:0] data_in);
        logic [7:0] c;
        c = crc_in ^ data_in;
        for (int i = 0; i < 8; i++) begin
            if (c[7])
                c = (c << 1) ^ 8'h07;
            else
                c = c << 1;
        end
        return c;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            hdr_idx        <= '0;
            pay_cnt        <= '0;
            crc_reg        <= 8'h00;
            frame_byte_out <= '0;
            frame_valid_out<= 1'b0;
            frame_last_out <= 1'b0;
            crc8_out       <= '0;
        end else begin
            frame_valid_out <= 1'b0;
            frame_last_out  <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (frame_start_in) begin
                        // Build header bytes
                        header[0] <= sync_words[protocol_id_in][15:8];
                        header[1] <= sync_words[protocol_id_in][7:0];
                        header[2] <= {6'b0, protocol_id_in};
                        header[3] <= dest_addr_in[15:8];
                        header[4] <= dest_addr_in[7:0];
                        header[5] <= src_addr_in[15:8];
                        header[6] <= src_addr_in[7:0];
                        header[7] <= channel_id_in;
                        header[8] <= 8'h00;
                        header[9] <= payload_len_in;
                        hdr_idx   <= '0;
                        pay_cnt   <= '0;
                        crc_reg   <= 8'h00;
                        state     <= S_EMIT_HEADER;
                    end
                end

                S_EMIT_HEADER: begin
                    frame_byte_out  <= header[hdr_idx];
                    frame_valid_out <= 1'b1;
                    crc_reg         <= crc8_update(crc_reg, header[hdr_idx]);

                    if (hdr_idx == 4'd9) begin
                        hdr_idx <= '0;
                        state   <= (payload_len_in > 0) ? S_EMIT_PAYLOAD : S_EMIT_CRC;
                    end else begin
                        hdr_idx <= hdr_idx + 1'b1;
                    end
                end

                S_EMIT_PAYLOAD: begin
                    if (payload_valid_in) begin
                        frame_byte_out  <= payload_byte_in;
                        frame_valid_out <= 1'b1;
                        crc_reg         <= crc8_update(crc_reg, payload_byte_in);
                        pay_cnt         <= pay_cnt + 1'b1;

                        if (pay_cnt + 1'b1 >= payload_len_in)
                            state <= S_EMIT_CRC;
                    end
                end

                S_EMIT_CRC: begin
                    frame_byte_out  <= crc_reg;
                    frame_valid_out <= 1'b1;
                    frame_last_out  <= 1'b1;
                    crc8_out        <= crc_reg;
                    state           <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_frame_terminates;
        @(posedge clk) disable iff (!rst_n)
        frame_start_in |-> ##[1:300] frame_last_out;
    endproperty
    assert_frame_terminates: assert property (p_frame_terminates);
    `endif

endmodule
