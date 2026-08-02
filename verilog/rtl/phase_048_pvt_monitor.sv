// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_048_pvt_monitor
// Description: On-Chip Temperature & Voltage Process Monitor (PVT Monitor) Engine
// Features: Autonomous PVT Corner Detection, Self-Healing Bias Trim DAC, Over-Temp/Under-Volt Alerts, Inline SVA

`timescale 1ns / 1ps

module phase_048_pvt_monitor #(
    parameter int SENSOR_BITS = 12
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // On-Die ADC Sensor Inputs
    input  logic [SENSOR_BITS-1:0]  temp_adc_in,
    input  logic [SENSOR_BITS-1:0]  volt_adc_in,
    input  logic                    sensor_valid_in,

    // PVT Status & Self-Healing Outputs
    output logic [1:0]              pvt_corner_out,     // 00=TYPICAL, 01=MARGINAL, 10=SLOW_HOT, 11=FAST_COLD
    output logic                    over_temp_alert_out,
    output logic                    under_volt_alert_out,
    output logic signed [7:0]       bias_trim_dac_out,
    output logic                    pvt_valid_out
);

    // Temperature threshold codes (12-bit, 0=-40C, 4095=+125C)
    // 110C threshold = ((110+40)/(125+40)) * 4095 = 3724
    localparam logic [SENSOR_BITS-1:0] TEMP_OVER_THRESH = 12'd3724;
    // 100C threshold = ((100+40)/(125+40)) * 4095 = 3476
    localparam logic [SENSOR_BITS-1:0] TEMP_HOT_THRESH  = 12'd3476;
    // -20C threshold = ((-20+40)/(125+40)) * 4095 = 496
    localparam logic [SENSOR_BITS-1:0] TEMP_COLD_THRESH = 12'd496;

    // Voltage threshold codes (12-bit, 0=0V, 4095=1.8V)
    // 0.95V threshold = (0.95/1.8) * 4095 = 2161
    localparam logic [SENSOR_BITS-1:0] VOLT_UNDER_THRESH = 12'd2161;
    // 1.08V threshold = (1.08/1.8) * 4095 = 2457
    localparam logic [SENSOR_BITS-1:0] VOLT_LOW_THRESH   = 12'd2457;
    // 1.44V threshold = (1.44/1.8) * 4095 = 3276
    localparam logic [SENSOR_BITS-1:0] VOLT_HIGH_THRESH  = 12'd3276;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pvt_corner_out       <= 2'b00;
            over_temp_alert_out  <= 1'b0;
            under_volt_alert_out <= 1'b0;
            bias_trim_dac_out    <= 8'sd0;
            pvt_valid_out        <= 1'b0;
        end else if (sensor_valid_in) begin
            // Over-temperature and under-voltage alerts
            over_temp_alert_out  <= (temp_adc_in > TEMP_OVER_THRESH);
            under_volt_alert_out <= (volt_adc_in < VOLT_UNDER_THRESH);

            // PVT corner classification
            if (temp_adc_in > TEMP_HOT_THRESH && volt_adc_in < VOLT_LOW_THRESH)
                pvt_corner_out <= 2'b10; // SLOW_HOT
            else if (temp_adc_in < TEMP_COLD_THRESH && volt_adc_in > VOLT_HIGH_THRESH)
                pvt_corner_out <= 2'b11; // FAST_COLD
            else if (temp_adc_in >= 12'd1613 && temp_adc_in <= 12'd3103 &&
                     volt_adc_in >= VOLT_LOW_THRESH && volt_adc_in <= VOLT_HIGH_THRESH)
                pvt_corner_out <= 2'b00; // TYPICAL
            else
                pvt_corner_out <= 2'b01; // MARGINAL

            // Bias trim DAC computation (simplified linear compensation)
            // temp_trim = (temp_adc - midpoint_25C) >> 5, volt_trim = (volt_adc - nominal_1.2V) >> 4
            logic signed [12:0] temp_offset;
            logic signed [12:0] volt_offset;
            temp_offset = $signed({1'b0, temp_adc_in}) - $signed(13'd1613);
            volt_offset = $signed({1'b0, volt_adc_in}) - $signed(13'd2731);
            bias_trim_dac_out <= $signed(temp_offset[12:5]) - $signed(volt_offset[12:3]);

            pvt_valid_out <= 1'b1;
        end else begin
            pvt_valid_out <= 1'b0;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_pvt_sync;
        @(posedge clk) disable iff (!rst_n)
        sensor_valid_in |=> pvt_valid_out;
    endproperty
    assert_pvt_sync: assert property (p_pvt_sync);

    property p_over_temp_latency;
        @(posedge clk) disable iff (!rst_n)
        (sensor_valid_in && temp_adc_in > TEMP_OVER_THRESH) |=> over_temp_alert_out;
    endproperty
    assert_over_temp_latency: assert property (p_over_temp_latency);
    `endif

endmodule
