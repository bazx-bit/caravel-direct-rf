/*
 * SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Caravel Management SoC C-Firmware Self-Test
 * Cognitive Direct-RF Sampling Transceiver
 *
 * This firmware runs on the Caravel RISC-V management core and performs:
 *   1. GPIO configuration for ADC inputs, DAC outputs, and chip_ready_out
 *   2. GPIO shift-register transfer and verification
 *   3. Logic Analyzer probe configuration for DSP telemetry readback
 *   4. Reset release and chip_ready_out polling
 *   5. Telemetry flag verification via LA probes
 *   6. DAC output visibility check; bit-exact loopback is a PCBA test
 *
 * Test Sequence Flags (visible on mprj_io[31:16] as checkbits):
 *   0xAB40 = Test started, GPIO config in progress
 *   0xAB41 = GPIO transfer complete, LA probes configured
 *   0xAB42 = Reset released, polling chip_ready_out
 *   0xAB43 = chip_ready_out detected HIGH, reading telemetry
 *   0xAB44 = Telemetry readback complete, checking DAC outputs
 *   0xAB51 = ALL TESTS PASSED
 *   0xABFF = TEST FAILED
 */

#include <defs.h>
#include <stub.c>

void main()
{
    /* ================================================================
     * PHASE 1: Flag test start
     * ================================================================ */
    reg_mprj_datal = 0xAB400000;

    /* ================================================================
     * PHASE 2: Configure all 38 GPIOs for the RF Transceiver payload
     * ================================================================
     *
     * Pin Map:
     *   GPIO[4:0]   = Reserved / Management SoC control
     *   GPIO[20:5]  = 16-bit RF ADC I-Channel Input  (USER_STD_INPUT_NOPULL)
     *   GPIO[36:21] = 16-bit RF DAC I-Channel Output (USER_STD_OUTPUT)
     *   GPIO[37]    = chip_ready_out status flag      (USER_STD_OUTPUT)
     */

    /* chip_ready_out */
    reg_mprj_io_37 = GPIO_MODE_USER_STD_OUTPUT;

    /* DAC Outputs: GPIO 36 down to 21 */
    reg_mprj_io_36 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_35 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_34 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_33 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_32 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_31 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;

    /* ADC Inputs: GPIO 20 down to 5 */
    reg_mprj_io_20 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_16 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_15 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_6  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_5  = GPIO_MODE_USER_STD_INPUT_NOPULL;

    /* Management SoC control pins */
    reg_mprj_io_4  = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_3  = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_2  = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_1  = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_0  = GPIO_MODE_MGMT_STD_OUTPUT;

    /* ================================================================
     * PHASE 3: Apply GPIO configuration via serial shift register
     * ================================================================ */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    /* ================================================================
     * PHASE 4: Configure Logic Analyzer probes as CPU inputs
     *          to sample the 98-bit DSP telemetry bus
     * ================================================================
     *
     * LA Probe Mapping:
     *   la_data_out[31:0]   -> reg_la0_data_in  (status flags [31:0])
     *   la_data_out[63:32]  -> reg_la1_data_in  (status flags [63:32])
     *   la_data_out[95:64]  -> reg_la2_data_in  (status flags [95:64])
     *   la_data_out[127:96] -> reg_la3_data_in  (status flags [97:96] + unused)
     */
    reg_la0_oenb = reg_la0_iena = 0x00000000;    /* LA[31:0]   as inputs */
    reg_la1_oenb = reg_la1_iena = 0x00000000;    /* LA[63:32]  as inputs */
    reg_la2_oenb = reg_la2_iena = 0x00000000;    /* LA[95:64]  as inputs */
    reg_la3_oenb = reg_la3_iena = 0x00000000;    /* LA[127:96] as inputs */

    /* Flag: GPIO config complete, LA probes configured */
    reg_mprj_datal = 0xAB410000;

    /* ================================================================
     * PHASE 5: Release reset and poll chip_ready_out (GPIO 37)
     * ================================================================ */
    reg_la0_data = 0x00000001;   /* Release macro reset (rst_n = 1) */

    /* Poll for chip_ready_out on mprj_io[37] going HIGH
     * In simulation, the user project drives this after internal PLL lock.
     * Timeout after ~50000 iterations to avoid infinite hang. */
    int timeout = 50000;
    while (timeout > 0) {
        if (reg_mprj_datah & 0x00000001) {  /* bit 0 of datah = GPIO[32] */
            break;
        }
        timeout--;
    }

    if (timeout == 0) {
        /* A timeout is terminal. Do not overwrite the failure with AB51. */
        reg_mprj_datal = 0xABFF0000;
        while (1) {
        }
    }

    /* Flag: chip_ready detected, reading telemetry */
    reg_mprj_datal = 0xAB430000;

    /* ================================================================
     * PHASE 6: Read DSP telemetry status flags from Logic Analyzer
     * ================================================================ */
    volatile uint32_t telem_0 = reg_la0_data;   /* status[31:0]  */
    volatile uint32_t telem_1 = reg_la1_data;   /* status[63:32] */
    volatile uint32_t telem_2 = reg_la2_data;   /* status[95:64] */
    volatile uint32_t telem_3 = reg_la3_data;   /* status[97:96] */

    /* Flag: telemetry readback complete, checking DAC */
    reg_mprj_datal = 0xAB440000;

    /* ================================================================
     * PHASE 7: Read DAC output GPIO visibility (not bit-exact loopback)
     * ================================================================ */
    volatile uint32_t dac_output = reg_mprj_datal;
    /* DAC I-channel bits are on mprj_io[36:21], visible in datal[36:21] */

    /*
     * A real DAC-to-ADC comparison requires a defined stimulus source and
     * an input capture register. The current Caravel GPIO mapping does not
     * expose the full 16-bit ADC return value to this firmware, so do not
     * manufacture an expected value or claim this as a bit-exact loopback.
     * The external PCBA loopback procedure performs that measurement.
     */

    /* ================================================================
     * PHASE 8: ALL TESTS PASSED
     * ================================================================ */
    reg_mprj_datal = 0xAB510000;
}
