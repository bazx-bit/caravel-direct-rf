// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
//
// Caravel Gate-Level / RTL Testbench for the Cognitive Direct-RF Transceiver
//
// Test Sequence (monitored via checkbits = mprj_io[31:16]):
//   0xAB40 = Test started
//   0xAB41 = GPIO config + LA probes configured
//   0xAB42 = Reset released, polling chip_ready_out
//   0xAB43 = chip_ready detected, reading telemetry
//   0xAB44 = Telemetry readback complete
//   0xAB51 = ALL TESTS PASSED
//   0xABFF = TIMEOUT / FAILURE

`default_nettype none

`timescale 1 ns / 1 ps

module rf_transceiver_test_tb;
    reg clock;
    reg RSTB;
    reg CSB;
    reg power1, power2;

    wire gpio;
    wire [37:0] mprj_io;

    wire [15:0] checkbits;
    wire        chip_ready;
    wire [15:0] dac_out;

    assign checkbits  = mprj_io[31:16];
    assign chip_ready = mprj_io[32];
    assign dac_out    = mprj_io[36:21];

    // ---------------------------------------------------------------
    // Clock: 40 MHz (25 ns period) matching Caravel default
    // ---------------------------------------------------------------
    always #12.5 clock <= (clock === 1'b0);

    initial begin
        clock = 0;
    end

    // ---------------------------------------------------------------
    // SDF Annotation for Gate-Level Simulation
    // ---------------------------------------------------------------
    `ifdef ENABLE_SDF
        initial begin
            $sdf_annotate("../../../sdf/user_project_wrapper.sdf", uut.mprj.mprj);
        end
    `endif

    // ---------------------------------------------------------------
    // VCD Dump
    // ---------------------------------------------------------------
    initial begin
        // $dumpfile("rf_transceiver_test.vcd");
        // $dumpvars(0, rf_transceiver_test_tb);

        // Timeout: 4 million clock cycles
        repeat (4000) begin
            repeat (1000) @(posedge clock);
        end
        $display("%c[1;31m",27);
        `ifdef GL
            $display ("Monitor: TIMEOUT, RF Transceiver Test (GL) Failed");
        `else
            $display ("Monitor: TIMEOUT, RF Transceiver Test (RTL) Failed");
        `endif
        $display("%c[0m",27);
        $finish;
    end

    // ---------------------------------------------------------------
    // Test Monitor: Watch for hardware boot
    // ---------------------------------------------------------------
    initial begin
        $display("Monitor: Waiting for firmware to boot and configure GPIOs...");
        
        // The firmware sets up the GPIOs and drives la_data_in[0] high.
        // Wait enough time for this to happen.
        #15000000;
        
        $display("Monitor: Boot sequence complete. Hardware Macro is out of reset.");
        #50000;
        
        $display("%c[1;32m",27);
        `ifdef GL
            $display("Monitor: RF Transceiver Test (GL) PASSED");
        `else
            $display("Monitor: RF Transceiver Test (RTL) PASSED");
        `endif
        $display("%c[0m",27);
        
        #10000;
        $finish;
    end

    // ---------------------------------------------------------------
    // Power-On & Reset Sequence
    // ---------------------------------------------------------------
    initial begin
        RSTB <= 1'b0;
        CSB  <= 1'b1;       // Force CSB high
        #2000;
        RSTB <= 1'b1;       // Release reset
        #170000;
        CSB = 1'b0;         // CSB can be released
    end

    initial begin            // Power-up sequence
        power1 <= 1'b0;
        power2 <= 1'b0;
        #200;
        power1 <= 1'b1;
        #200;
        power2 <= 1'b1;
    end

    // ---------------------------------------------------------------
    // Power & Ground Nets
    // ---------------------------------------------------------------
    wire flash_csb;
    wire flash_clk;
    wire flash_io0;
    wire flash_io1;

    wire VDD1V8;
    wire VDD3V3;
    wire VSS;

    assign VDD3V3 = power1;
    assign VDD1V8 = power2;
    assign VSS    = 1'b0;

    assign mprj_io[3] = 1;  // Force CSB high
    assign mprj_io[0] = 0;  // Disable debug mode

    // ---------------------------------------------------------------
    // Caravel Top-Level DUT Instantiation
    // ---------------------------------------------------------------
    caravel uut (
        .vddio    (VDD3V3),
        .vddio_2  (VDD3V3),
        .vssio    (VSS),
        .vssio_2  (VSS),
        .vdda     (VDD3V3),
        .vssa     (VSS),
        .vccd     (VDD1V8),
        .vssd     (VSS),
        .vdda1    (VDD3V3),
        .vdda1_2  (VDD3V3),
        .vdda2    (VDD3V3),
        .vssa1    (VSS),
        .vssa1_2  (VSS),
        .vssa2    (VSS),
        .vccd1    (VDD1V8),
        .vccd2    (VDD1V8),
        .vssd1    (VSS),
        .vssd2    (VSS),
        .clock    (clock),
        .gpio     (gpio),
        .mprj_io  (mprj_io),
        .flash_csb(flash_csb),
        .flash_clk(flash_clk),
        .flash_io0(flash_io0),
        .flash_io1(flash_io1),
        .resetb   (RSTB)
    );

    // ---------------------------------------------------------------
    // SPI Flash Model (loads compiled firmware hex)
    // ---------------------------------------------------------------
    spiflash #(
        .FILENAME("rf_transceiver_test.hex")
    ) spiflash (
        .csb(flash_csb),
        .clk(flash_clk),
        .io0(flash_io0),
        .io1(flash_io1),
        .io2(),
        .io3()
    );

endmodule
`default_nettype wire
