# Focused Application Brief

## Product

**Open Direct-RF DSP Evaluation ASIC**

## One Problem

Small research teams need a reproducible, low-cost silicon platform for
evaluating direct-RF DSP pipelines without designing a complete commercial
radio SoC.

## What This Submission Does

- Provides a Caravel-integrated SKY130 digital/DSP control prototype.
- Connects a 100-phase DSP pipeline to documented GPIO and logic-analyzer
  interfaces.
- Provides management-SoC firmware for reset, GPIO configuration, telemetry,
  and status reporting.
- Provides OpenLane physical views and an official MPW precheck result.
- Provides a PCBA and post-silicon measurement plan.

## What It Does Not Claim

- It is not a fabricated 2.4 GSps RF front end.
- It does not contain measured ADC/DAC ENOB, SNR, SFDR, power, or temperature
  results.
- The Sky130 implementation is a digital/DSP proof platform; RF performance is
  measured only after silicon and board bring-up.

## Demonstration Path

```text
Caravel management firmware
        -> GPIO and logic-analyzer configuration
        -> DSP macro reset/status/telemetry
        -> RTL and gate-level verification
        -> OpenLane physical implementation
        -> Official MPW precheck
        -> Future QFN/PCBA measurement
```

## Why This Is a Stronger Submission Story

The design is intentionally presented as one reproducible evaluation platform,
not four finished commercial products. The future NEXUS variants remain a
roadmap; this submission is judged on the focused Sky130 design and its
reproducible silicon-to-board path.

## Current Evidence

- Precheck log: `precheck_results/28_JUL_2026___09_55_48/logs/precheck.log`
- Firmware: `verilog/dv/rf_transceiver_test/rf_transceiver_test.c`
- Gate-level testbench: `verilog/dv/rf_transceiver_test/rf_transceiver_test_tb.v`
- PCBA schematic: `pcb/rf_transceiver_breakout.kicad_sch`
- Mechanical concept: `mechanicals/enclosure_spec.scad`
- Post-silicon plan: `docs/POST_SILICON_VALIDATION_PLAN.md`

