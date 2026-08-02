// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
// SystemVerilog IEEE 1800 Implementation
// Module: phase_051_dvfs_controller
// Description: Autonomous Power Management & Dynamic Voltage-Frequency Scaling (DVFS) Controller Core
// Features: Closed-Loop DVFS Power State Machine, Workload & Over-Temp Adaptation, Inline SVA

`timescale 1ns / 1ps

module phase_051_dvfs_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Workload & Sensor Monitoring Inputs
    input  logic [7:0]  utilization_pct_in, // 0 to 100%
    input  logic        over_temp_alert_in,
    input  logic        sleep_req_in,
    input  logic        force_pstate_valid_in,
    input  logic [1:0]  force_pstate_in,

    // DVFS Outputs
    output logic [1:0]  pstate_out,          // 00=PERF, 01=BAL, 10=LOW_PWR, 11=SLEEP
    output logic [2:0]  clk_div_out,         // 1=div1, 2=div2, 4=div4, 0=gated
    output logic [3:0]  vdd_dac_out,         // PMIC DAC code
    output logic        dvfs_valid_out
);

    typedef enum logic [1:0] {
        PSTATE_PERF    = 2'b00,
        PSTATE_BAL     = 2'b01,
        PSTATE_LOW_PWR = 2'b10,
        PSTATE_SLEEP   = 2'b11
    } pstate_t;

    pstate_t current_pstate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pstate <= PSTATE_BAL;
            pstate_out     <= 2'b01;
            clk_div_out    <= 3'd2;
            vdd_dac_out    <= 4'hA;
            dvfs_valid_out <= 1'b0;
        end else begin
            // Next State Logic
            if (sleep_req_in) begin
                current_pstate <= PSTATE_SLEEP;
            end else if (over_temp_alert_in) begin
                // Emergency Thermal Throttling
                current_pstate <= PSTATE_LOW_PWR;
            end else if (force_pstate_valid_in) begin
                current_pstate <= pstate_t'(force_pstate_in);
            end else begin
                if (utilization_pct_in > 8'd75)
                    current_pstate <= PSTATE_PERF;
                else if (utilization_pct_in < 8'd25)
                    current_pstate <= PSTATE_LOW_PWR;
                else
                    current_pstate <= PSTATE_BAL;
            end

            // Output Assignment
            pstate_out <= current_pstate;
            case (current_pstate)
                PSTATE_PERF: begin
                    clk_div_out <= 3'd1;
                    vdd_dac_out <= 4'hF; // 1.2V
                end
                PSTATE_BAL: begin
                    clk_div_out <= 3'd2;
                    vdd_dac_out <= 4'hA; // 1.0V
                end
                PSTATE_LOW_PWR: begin
                    clk_div_out <= 3'd4;
                    vdd_dac_out <= 4'h5; // 0.8V
                end
                PSTATE_SLEEP: begin
                    clk_div_out <= 3'd0; // Gated
                    vdd_dac_out <= 4'h1; // 0.6V
                end
                default: begin
                    clk_div_out <= 3'd2;
                    vdd_dac_out <= 4'hA;
                end
            endcase

            dvfs_valid_out <= 1'b1;
        end
    end

    // =========================================================================
    // INLINE SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    `ifndef SYNTHESIS
    property p_thermal_throttle;
        @(posedge clk) disable iff (!rst_n)
        over_temp_alert_in |=> (pstate_out == PSTATE_LOW_PWR);
    endproperty
    assert_thermal_throttle: assert property (p_thermal_throttle);

    property p_sleep_override;
        @(posedge clk) disable iff (!rst_n)
        sleep_req_in |=> (pstate_out == PSTATE_SLEEP);
    endproperty
    assert_sleep_override: assert property (p_sleep_override);
    `endif

endmodule
