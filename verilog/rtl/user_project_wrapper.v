// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * Wraps the hardened phase_099_top_integration macro
 * (Cognitive Direct-RF Sampling Transceiver) inside the
 * Caravel padframe harness for eFabless MPW shuttle.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* Cognitive Direct-RF Transceiver      */
/* Hardened Macro Instantiation         */
/*--------------------------------------*/

    // Internal wires for macro connections
    wire signed [15:0] rf_adc_i_in;
    wire signed [15:0] rf_adc_q_in;
    wire signed [15:0] rf_dac_i_out;
    wire signed [15:0] rf_dac_q_out;
    wire [97:0] module_status_flags_out;
    wire        chip_ready_out;

    // Map Caravel IO pads to transceiver ADC/DAC signals
    // io_in[15:0]  -> ADC I-channel input
    // io_in[31:16] -> ADC Q-channel input
    assign rf_adc_i_in = io_in[15:0];
    assign rf_adc_q_in = io_in[31:16];

    // Map transceiver DAC outputs to Caravel IO pads
    // io_out[15:0]  -> DAC I-channel output
    // io_out[31:16] -> DAC Q-channel output
    // io_out[32]    -> chip_ready flag
    // io_out[37:33] -> status flags [4:0]
    assign io_out[15:0]  = rf_dac_i_out;
    assign io_out[31:16] = rf_dac_q_out;
    assign io_out[32]    = chip_ready_out;
    assign io_out[37:33] = module_status_flags_out[4:0];

    // Direct structural bus mapping (zero logic operators)
    assign io_oeb = la_oenb[`MPRJ_IO_PADS-1:0];

    // Instantiate the hardened macro
    phase_099_top_integration mprj (
        .clk_2p4g(user_clock2),
        .clk_dsp(wb_clk_i),
        .rst_n(la_data_in[0]),    // Direct wire connection from LA probe 0
        .rf_adc_i_in(rf_adc_i_in),
        .rf_adc_q_in(rf_adc_q_in),
        .rf_dac_i_out(rf_dac_i_out),
        .rf_dac_q_out(rf_dac_q_out),
        .module_status_flags_out(module_status_flags_out),
        .chip_ready_out(chip_ready_out)
    );

    // Direct structural wire connections (zero unmapped primitives)
    assign wbs_ack_o = wbs_stb_i;
    assign wbs_dat_o = module_status_flags_out[31:0];

    // Logic Analyzer telemetry routing
    assign la_data_out[97:0]   = module_status_flags_out;
    assign la_data_out[127:98] = la_data_in[29:0];

    // Interrupts driven by telemetry status flags
    assign user_irq = module_status_flags_out[34:32];

endmodule	// user_project_wrapper

`default_nettype wire
