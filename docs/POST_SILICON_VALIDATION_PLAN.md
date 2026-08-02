# Post-Silicon Validation & RF Measurement Plan
## Cognitive Direct-RF Sampling Transceiver — Silicon Return Test Procedure

---

### 1. Overview
This document specifies the exact measurement procedures to be executed upon receipt of the 50 QFN-64 packaged silicon parts from the ChipFoundry chipIgnite shuttle. All measurements will be compared against the Python golden reference models (`src/golden/`) to validate silicon-vs-simulation parity.

---

### 2. Expected Operating Parameters

| Parameter | Design Target | Measurement Method |
| :--- | :--- | :--- |
| **System Clock (wb_clk_i)** | 40 MHz (Caravel PLL input) | Oscilloscope probe on clock pin |
| **DSP Clock (clk_dsp)** | Derived from PLL (target up to 100 MHz on Sky130) | Internal, observed via LA telemetry |
| **GPIO I/O Voltage** | 3.3V LVCMOS (pad ring) | Multimeter on VDDIO rail |
| **Core Logic Voltage** | 1.8V (VCCD1) | Multimeter on VCCD1 rail |
| **Quiescent Power (Idle)** | < 50 mW estimated | Power supply current readback |
| **Active Power (DSP Running)** | < 200 mW estimated | Power supply current readback |

---

### 3. Test Vectors & Validation Procedures

#### 3.1 Test 1: Power-On & Firmware Boot
- **Procedure:** Apply 3.3V and 1.8V, release reset, observe GPIO[37] (`chip_ready_out`) going HIGH.
- **Pass Criteria:** `chip_ready_out` asserts within 500ms of reset release.
- **Equipment:** Power supply, oscilloscope.

#### 3.2 Test 2: Logic Analyzer Telemetry Readback
- **Procedure:** Connect Caravel development board to FTDI/USB bridge. Read `la_data_out[97:0]` via the management SoC Wishbone interface using `caravel_board` firmware utilities.
- **Pass Criteria:** Telemetry flags match the expected reset-state values defined in `src/golden/phase_099_top_integration.py`.
- **Equipment:** Caravel dev board, USB cable, terminal.

#### 3.3 Test 3: Digital Loopback (DAC-to-ADC)
- **Procedure:** Wire DAC outputs (GPIO 21–36) directly to ADC inputs (GPIO 5–20) with 16 jumper wires. Program DSP to output a 1 kHz full-scale digital sine sweep. Read back ADC inputs and compare.
- **Pass Criteria:** Zero bit errors across 1000 sample cycles.
- **Equipment:** Jumper wires, logic analyzer.

#### 3.4 Test 4: DSP Impulse Response Verification
- **Procedure:** Inject a single-sample digital impulse (0x7FFF followed by 0x0000) into ADC inputs. Capture the DAC output response over 256 samples.
- **Pass Criteria:** Impulse response envelope matches the Python golden CIC + FIR filter cascade response within ±1 LSB.
- **Equipment:** Waveform generator (parallel digital mode), logic analyzer.

#### 3.5 Test 5: NCO Frequency Accuracy
- **Procedure:** Configure the NCO phase accumulator to target output frequency = 1 MHz. Capture 4096 DAC output samples. Perform FFT analysis.
- **Pass Criteria:** FFT peak within ±100 Hz of target. Spurious-Free Dynamic Range (SFDR) > 60 dBc.
- **Equipment:** Logic analyzer, Python FFT analysis script.

---

### 4. RF Performance Metrics (Post-Silicon Characterization)

| Metric | Target | Measurement Method |
| :--- | :--- | :--- |
| **ENOB (Effective Number of Bits)** | > 10 bits at baseband | SINAD measurement from FFT of captured DAC output |
| **SNR (Signal-to-Noise Ratio)** | > 62 dB | FFT noise floor analysis |
| **SFDR (Spurious-Free Dynamic Range)** | > 60 dBc | FFT spur identification |
| **Latency (Input-to-Output)** | < 100 clock cycles | Impulse stimulus-to-response timing on oscilloscope |
| **Power Consumption (Active)** | < 200 mW | V × I measurement on VCCD1 rail |

---

### 5. Known Pre-Silicon Limitations & Honest Disclosure

> **IMPORTANT:** The following performance targets are *design-intent* values derived from RTL simulation and Python golden models. They have NOT been measured on physical silicon. Actual silicon performance may differ due to:
> - Process variation (PVT corners)
> - On-die IR drop and supply noise
> - Parasitic capacitance not captured in digital-only extraction
> - Clock jitter from the Caravel PLL
>
> The 2.4 GSps direct-RF sampling target specified in the architectural documents refers to the mathematical DSP pipeline clock domain design target on IHP SG13G2 (250 GHz fT BiCMOS). On the SkyWater 130nm CMOS shuttle, the realizable DSP clock frequency will be determined by actual silicon timing and is expected to be in the range of 50–150 MHz, which validates the digital architecture at a lower sample rate.

---

### 6. Tool & PDK Version Manifest

| Tool / Component | Version | Source |
| :--- | :--- | :--- |
| **PDK** | sky130_fd_sc_hd (SkyWater 130nm) | [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk) |
| **OpenLane** | 2.x (OpenROAD-based flow) | [github.com/The-OpenROAD-Project/OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) |
| **Yosys** | 0.38+ | Open-source RTL synthesizer |
| **Magic VLSI** | 8.3.x | DRC & extraction |
| **KLayout** | 0.28.x | FEOL/BEOL/Offgrid DRC |
| **Netgen** | 1.5.x | LVS |
| **Caravel Harness** | caravel v2 (chipfoundry fork) | [github.com/chipfoundry/caravel_user_project](https://github.com/chipfoundry/caravel_user_project) |
| **mpw_precheck** | efabless/mpw_precheck:latest | Docker container |

---

### 7. Shuttle & Deadline Confirmation

| Item | Detail |
| :--- | :--- |
| **Platform** | ChipFoundry chipIgnite |
| **Target Shuttles** | September 2026 or December 2026 (per platform.chipfoundry.io/status) |
| **Precheck Status** | **PASSED** — 14/14 checks clean (`{{SUCCESS}} All Checks Passed !!!`) |
| **Precheck Log Preserved** | Yes — stored in `openlane/user_project_wrapper/runs/wrapper_run/logs/` |
