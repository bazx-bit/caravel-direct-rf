# Cognitive Direct-RF Sampling Transceiver — Caravel User Project

> **Status:** Caravel-integrated Sky130 physical-design prototype with generated wrapper GDS and 14/14 OpenLane precheck signoff artifacts.

> [!IMPORTANT]
> **Architectural Scope & Honest Pre-Tapeout Disclosure:**
> This design is a **100-phase Digital SDR Baseband & DSP Engine** implemented on SkyWater 130nm CMOS.
> - **Digital CMOS Scope:** The macro contains pure digital standard-cell logic (`sky130_fd_sc_hd`). The ADC/DAC interfaces are 16-bit digital buses (`io_in`/`io_out`) designed to interface with external converters.
> - **Clock Speeds:** On Sky130 CMOS, the digital DSP pipeline operates at standard digital logic clock speeds (~50–100 MHz).
> - **2.4 GSps Target:** The 2.4 GSps direct-RF sampling specification represents the mathematical target architecture for a future SiGe BiCMOS (IHP SG13G2) port with 250 GHz $f_T$ HBTs.
> - **Pre-Silicon Status:** No physical silicon measurements (ENOB, SNR, SFDR, RF power) are claimed prior to fabrication and lab testing.

## Overview

This project implements a **100-phase DSP pipeline** for a direct-RF sampling transceiver architecture, hardened as a single macro (`phase_099_top_integration`) and integrated into the Efabless Caravel harness (`user_project_wrapper`) for MPW shuttle submission on the **SkyWater 130nm** open-source PDK (`sky130A`).

### Key Specifications

| Parameter | Value |
|---|---|
| **PDK** | SkyWater `sky130A` (`sky130_fd_sc_hd` standard cell library) |
| **Macro Die Area** | 1200 × 1200 µm² |
| **Wrapper Die Area** | 2920 × 3520 µm² (Caravel standard) |
| **Logic Gates** | 30,615 |
| **Flip-Flops** | 3,142 |
| **DSP Phases** | 100 (DDS, CIC, FIR, FFT, QAM, CRC32, AXI-Lite, AGC, CFR, BIST, …) |
| **Verification Tests** | 491 pytest suites — 100% pass |

## Architecture

```
Caravel Harness (user_project_wrapper)
├── Power: vccd1/vssd1 → macro VPWR/VGND
├── Clocks: wb_clk_i → clk_dsp, user_clock2 → clk_2p4g
├── Reset: la_data_in[0] → rst_n (active-low, firmware-controlled)
├── ADC Input: io_in[15:0] → rf_adc_i_in, io_in[31:16] → rf_adc_q_in
├── DAC Output: io_out[15:0] → rf_dac_i_out, io_out[31:16] → rf_dac_q_out
├── Status: io_out[37:32] → chip_ready + status_flags[4:0]
├── Wishbone: wbs_ack_o ← wbs_stb_i, wbs_dat_o ← status_flags[31:0]
├── Logic Analyzer: la_data_out[97:0] ← module_status_flags_out
└── Interrupts: user_irq[2:0] ← status_flags[34:32]
```

## Build & Harden

### Prerequisites

- Docker
- OpenLane 1 (`efabless/openlane:2023.07.19-1`)
- SkyWater 130nm PDK (installed via `volare`)
- Python 3.11+ with `numpy`, `scipy`, `pytest`

### Step 1: Harden the Macro

```bash
cd openlane
make phase_099_top_integration
```

### Step 2: Harden the Wrapper

```bash
cd openlane
make user_project_wrapper
```

### Step 3: Run Verification

```bash
python -m pytest tests/ -v
```

### Step 4: Run Official Precheck

```bash
make run-precheck
```

## Physical Signoff Summary

| Check | Tool | Result |
|---|---|---|
| **Detailed Routing** | OpenROAD | 0 DRC violations |
| **Layout XOR** | KLayout | 0 differences |
| **Magic DRC** | Magic 8.3 | 0 violations |
| **Netgen LVS** | Netgen 1.5 | 0 unmatched nets, 0 unmatched devices |
| **Multicorner STA** | OpenROAD | min/nom/max corners verified |
| **Gate-Level Sim** | pytest | 4/4 passed |

## Verification Boundary

The package is a Sky130 digital/DSP prototype. The 2.4 GSps direct-RF
architecture is a future technology target, not a measured Sky130 result.
The Sky130 implementation is expected to operate at a substantially lower
digital clock rate until silicon timing and the external RF interface are
measured. No RF ENOB, SNR, SFDR, power, or silicon frequency result is claimed
before fabrication and laboratory characterization.

## Caravel Firmware Test

The management-SoC firmware self-test is at
`verilog/dv/rf_transceiver_test/rf_transceiver_test.c`, with its RTL/GL
testbench at `verilog/dv/rf_transceiver_test/rf_transceiver_test_tb.v`.
The firmware reports terminal failure on reset/chip-ready timeout. The
bit-exact DAC-to-ADC loopback is intentionally a post-silicon PCBA test,
because the current GPIO mapping does not expose a full ADC capture register
to the management firmware.

## Complete Reference-Design Materials

- Firmware/GL test: `verilog/dv/rf_transceiver_test/`
- PCBA plan and schematic: `pcb/PCBA_EVALUATION_PLAN.md` and
  `pcb/rf_transceiver_breakout.kicad_sch`
- Mechanical concept: `mechanicals/enclosure_spec.scad`
- Post-silicon plan: `docs/POST_SILICON_VALIDATION_PLAN.md`
- Video and screenshot checklist: `docs/VIDEO_AND_SCREENSHOT_PACKAGE.md`

## Submission Evidence

The latest official precheck log is stored under
`precheck_results/28_JUL_2026___09_55_48/logs/precheck.log` and ends with
`SUCCESS - All Checks Passed`. Confirm the target shuttle's current deadline,
area definition, required video, and any firmware/PCBA deliverables before
uploading.

## Directory Structure

```
caravel_user_project/
├── gds/                    # GDSII layouts
│   ├── user_project_wrapper.gds    (86.63 MB)
│   └── phase_099_top_integration.gds (85.32 MB)
├── lef/                    # LEF abstracts
├── def/                    # DEF floorplans
├── sdf/                    # SDF timing delays
├── spef/                   # SPEF parasitics (multicorner)
├── verilog/
│   ├── rtl/                # RTL source (user_project_wrapper.v, user_defines.v)
│   └── gl/                 # Gate-level netlists
├── openlane/               # OpenLane configurations
│   └── user_project_wrapper/
├── signoff/                # DRC, LVS, STA reports
└── info.yaml               # Project metadata
```

## License

SPDX-License-Identifier: Apache-2.0
