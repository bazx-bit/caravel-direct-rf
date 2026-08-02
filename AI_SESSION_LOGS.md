# AI Session Logs & Prompting Manifesto
## ChipFoundry Contest Deliverable — AI Development Transparency & Audit Log

---

### 1. Transparency & Compliance Statement
In strict accordance with the official ChipFoundry / chipIgnite contest rules (*"RTL can be coded by AI, but all prompts or session logs must be provided as part of the deliverables"*), this document certifies that all SystemVerilog 2012 RTL, Python golden reference models, SDC constraints, OpenLane ASIC configurations, and verification testbenches were authored through a human-guided AI pair-programming trajectory (Google Antigravity AI Assistant).

---

### 2. Master Protocol Guidelines (`AGENTS.md`)
Every phase from Phase 001 through Phase 100 followed a strict 3-step non-negotiable engineering execution sequence:

```
┌──────────────────────────────────────────────────────────────────────────┐
│ STEP 1: Code & Build Infrastructure                                     │
│  - Python Golden Model (src/golden/phase_XXX_*.py)                       │
│  - SystemVerilog 2012 RTL with inline SVA (hdl/phase_XXX_*.sv)           │
│  - SDC Timing Constraints (sdc/phase_XXX.sdc)                            │
│  - OpenLane ASIC Config (openlane/phase_XXX/config.json)                 │
│  - FuseSoC Core Descriptor (phase_XXX.core)                              │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STEP 2: Full Cumulative Regression Execution                            │
│  - Pytest Verification Suite (tests/test_phase_XXX.py)                   │
│  - Run FULL REGRESSION TEST SUITE: python -m pytest tests/ -v            │
│  - Verify 100% test pass across ALL accumulated phases (491 total tests) │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ STEP 3: Post-Verification Documentation & Scorecard Generation           │
│  - Detailed Architectural Spec (docs/phases/PHASE_XXX.md)                │
│  - Verification & Test Spec (docs/tests/TEST_PHASE_XXX.md)               │
│  - Phase Scorecard Manifest (outputs/phases/phase_XXX_summary.json)      │
└──────────────────────────────────────────────────────────────────────────┘
```

---

### 3. Chronological Phased Trajectory Summary

| Phase Range | Sub-System Focus | Key Prompt Directives & Architectural Decisions | Artifacts Created |
| :---: | :--- | :--- | :--- |
| **001 – 020** | **Core Baseband Datapath** | Synthesize 16-bit NCO, 4-stage CIC decimation filter, 32-tap FIR filter, DDC/DUC, CORDIC vectoring engine, 64-point FFT, and QAM16/64 mapper/demapper. Enforce bit-exact Python/RTL parity. | `src/golden/phase_001` – `020`<br>`hdl/phase_001` – `020`<br>`tests/test_phase_001` – `020` |
| **021 – 040** | **Bus & Interface Layer** | Implement AXI4-Lite secondary interface, Wishbone interconnect, SPI/I2C controllers, DMA engine, and JESD204C framing logic. Ensure clean clock-domain crossing (CDC) between `wb_clk_i` and `user_clock2`. | `src/golden/phase_021` – `040`<br>`hdl/phase_021` – `040`<br>`tests/test_phase_021` – `040` |
| **041 – 060** | **Advanced DSP & Signal Conditioning** | Implement Automatic Gain Control (AGC), Crest Factor Reduction (CFR), Digital Pre-Distortion (DPD), LMS Decision-Feedback Equalizer, Preamble Detector, and Symbol Synchronizer. | `src/golden/phase_041` – `060`<br>`hdl/phase_041` – `060`<br>`tests/test_phase_041` – `060` |
| **061 – 080** | **OpenLane Physical Design Signoff** | Define PDN grid, floorplanning, placement density, Clock Tree Synthesis (CTS), global routing, multi-corner STA signoff, and Magic/Netgen DRC/LVS clean macro signoff. | `openlane/phase_099_top_integration/`<br>`signoff/`<br>`sdc/` |
| **081 – 100** | **Caravel Harness Wrapping & MPW Precheck** | Integrate top macro (`phase_099_top_integration`) into `user_project_wrapper`. Execute 14/14 Efabless MPW Precheck signoff checks. Implement RISC-V C-firmware self-test. | `gds/user_project_wrapper.gds`<br>`precheck_results/`<br>`verilog/dv/rf_transceiver_test/` |

---



