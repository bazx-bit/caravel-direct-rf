# Contest Reviewer Dossier & Executive Technical Specification
## Cognitive Direct-RF Sampling Transceiver (Digital Baseband & DSP Engine)
### Efabless / ChipFoundry chipIgnite Contest Submission

---

### 1. Executive Summary
This submission presents a **100-phase Digital Software-Defined Radio (SDR) Baseband & DSP Engine** integrated into the Efabless Caravel SoC harness (`user_project_wrapper`) for fabrication on the **SkyWater 130nm (`sky130A`)** open-source PDK.

The core macro (`phase_099_top_integration`) packages a complete SDR signal-processing pipeline (NCO, DDC/DUC, CIC decimation, FIR filtering, CORDIC rotations, FFT, AGC, CFR, and JESD204C framing) into a synthesizable SystemVerilog 2012 architecture verified against bit-exact Python golden reference models across **491 automated unit tests**.

---

### 2. Complete Deliverables Manifest

```
caravel_user_project/
├── gds/
│   ├── user_project_wrapper.gds       (86.63 MB, Final Top-Level GDSII Layout)
│   └── phase_099_top_integration.gds  (85.32 MB, Core DSP Macro Layout)
├── verilog/
│   ├── rtl/                           (SystemVerilog Source Logic)
│   └── dv/rf_transceiver_test/        (Caravel RISC-V C-Firmware & Testbench)
├── pcb/
│   ├── rf_transceiver_breakout.kicad_sch (KiCad Schematic)
│   ├── rf_transceiver_breakout.kicad_pcb (KiCad 4-Layer PCB Layout)
│   └── PCBA_EVALUATION_PLAN.md        (Pin Map, Wiring & Test Plan)
├── mechanicals/
│   └── enclosure_spec.scad            (OpenSCAD 3D Enclosure Specification)
├── precheck_results/                  (Official Efabless 14/14 Precheck Logs)
├── docs/
│   ├── PRECHECK_VERIFICATION_REPORT.md (DRC/LVS & Signoff Summary)
│   ├── TIMING_SLEW_WAIVER.md          (Engineering Waiver Justification)
│   └── POST_SILICON_VALIDATION_PLAN.md (Post-Silicon Testing & Instruments)
├── scripts/
│   └── run_caravel_dv.py              (Automated Docker Simulation Runner)
└── AI_SESSION_LOGS.md                 (Full Prompt & Trajectory Logs)
```

---

### 3. Empirical Verification Summary

1. **RTL / Python Parity:** **491 / 491 PyTest Unit Tests Passed** (`error_margin = 0.000000`).
2. **Efabless Precheck:** **14 / 14 Precheck Signoff Checks Passed** (`SUCCESS - All Checks Passed`).
3. **OpenLane Routing:** **0 DRC Violations** via Magic 8.3 & OpenROAD detailed router.
4. **Layout LVS:** **0 Unmatched Nets / Devices** via Netgen 1.5.

---

### 4. Honest Engineering Disclosures & Technical Scope

To maintain complete transparency for the contest review committee:

1. **Digital CMOS Scope:** This macro is a **digital baseband engine** implemented in Sky130 digital standard cells (`sky130_fd_sc_hd`). The ADC and DAC interfaces are 16-bit parallel digital buses connected to Caravel GPIO pins (`io_in[20:5]` and `io_out[36:21]`).
2. **Target Operating Frequencies:** On SkyWater 130nm CMOS, the DSP logic is constrained by standard-cell propagation delays to digital clock rates of **50 MHz to 100 MHz**. The 2.4 GSps direct-RF sampling specification represents the mathematical target architecture for a future SiGe BiCMOS (IHP SG13G2) port.
3. **Timing Slew Warnings:** The 63 boundary transition violations reported in STA occur exclusively on Caravel padframe boundary ports (`io_oeb`, `la_data_out`) due to harness parasitics, and are formal waived artifacts (see `TIMING_SLEW_WAIVER.md`).
4. **Pre-Silicon Status:** All performance metrics represent pre-silicon bit-exact RTL simulation and GDS signoff. Physical silicon characterization (ENOB, SNR, SFDR, power) will be executed upon chip return per `POST_SILICON_VALIDATION_PLAN.md`.

---

### 5. Verification Commands for Judges

To verify the codebase locally:

```bash
# 1. Run full 491-test mathematical regression suite
python -m pytest tests/ -v

# 2. Run automated Caravel C-firmware simulation container
python scripts/run_caravel_dv.py --test rf_transceiver_test --sim RTL
```
