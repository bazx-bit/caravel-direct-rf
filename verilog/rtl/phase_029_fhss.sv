// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_029_fhss
// Description: Frequency-Hopping Spread Spectrum (FHSS) Fast Retuner Engine
// Features: 10,000 Hops/Sec, 256 Hopping Channels, 32-bit Galois LFSR PRNG, Inline SVA

`timescale 1ns / 1ps

module phase_029_fhss #(
    parameter int DEFAULT_SEED = 32'hACE1
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_hopping,
    input  logic [15:0] dwell_time_cycles, // Dwell duration before hop
    input  logic [31:0] base_ftw,
    input  logic [31:0] channel_spacing,
    output logic [7:0]  current_channel,
    output logic [31:0] ftw_out,
    output logic        hop_strobe
);

    logic [31:0] lfsr;
    logic [15:0] timer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr            <= DEFAULT_SEED;
            timer           <= '0;
            current_channel <= '0;
            ftw_out         <= base_ftw;
            hop_strobe      <= 1'b0;
        end else if (enable_hopping) begin
            if (timer >= dwell_time_cycles) begin
                timer <= '0;
                
                // 32-bit Galois LFSR Galois polynomial
                logic bit_fb;
                bit_fb = lfsr[0] ^ lfsr[1] ^ lfsr[3] ^ lfsr[12];
                lfsr   <= (lfsr >> 1) | (bit_fb << 31);

                current_channel <= lfsr[7:0];
                ftw_out         <= base_ftw + (lfsr[7:0] * channel_spacing);
                hop_strobe      <= 1'b1;
            end else begin
                timer      <= timer + 1'b1;
                hop_strobe <= 1'b0;
            end
        end else begin
            hop_strobe <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_fhss_strobe_pulse;
        @(posedge clk) disable iff (!rst_n)
        hop_strobe |=> !hop_strobe;
    endproperty
    assert_fhss_strobe_pulse: assert property (p_fhss_strobe_pulse);
    `endif

endmodule
