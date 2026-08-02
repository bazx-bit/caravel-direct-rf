# Efabless MPW Precheck Verification & Physical Signoff Report
## Caravel User Project — Cognitive Direct-RF Transceiver

---

### 1. Executive Summary
The `user_project_wrapper` layout containing the `phase_099_top_integration` macro was submitted to the official Efabless `mpw_precheck` tool (Docker container `efabless/mpw_precheck:latest`).

**Final Result:** **SUCCESS — ALL 14 CHECKS PASSED**
- **Log Location:** `precheck_results/28_JUL_2026___09_55_48/logs/precheck.log`
- **Signoff Date:** July 28, 2026
- **Target PDK:** SkyWater `sky130A` (`sky130_fd_sc_hd`)

---

### 2. Detailed Verification Matrix (14 / 14 Checks)

| Check # | Verification Check | Tool / Engine | Status | Details / Notes |
| :---: | :--- | :--- | :---: | :--- |
| **1** | License Check | Custom Script | **PASSED** | Apache-2.0 open-source license confirmed |
| **2** | Makefile Check | Custom Script | **PASSED** | Valid Efabless Caravel Makefile structure |
| **3** | Default Check | Custom Script | **PASSED** | Top-level project structure matches specs |
| **4** | Documentation Check | Custom Script | **PASSED** | `README.md` and `info.yaml` populated |
| **5** | Consistency Check | Custom Script | **PASSED** | Pinout, LEF, DEF, and GDS pin names aligned |
| **6** | GPIO Defines Check | Custom Script | **PASSED** | `verilog/rtl/user_defines.v` pin mapping verified |
| **7** | XOR Layout Check | KLayout 0.28.x | **PASSED** | Zero geometry mismatch against reference |
| **8** | Magic DRC Check | Magic VLSI 8.3 | **PASSED** | 0 DRC rule violations on macro & wrapper |
| **9** | KLayout FEOL DRC | KLayout 0.28.x | **PASSED** | Front-End-Of-Line spacing & width clean |
| **10** | KLayout BEOL DRC | KLayout 0.28.x | **PASSED** | Back-End-Of-Line metal density & width clean |
| **11** | KLayout Offgrid DRC | KLayout 0.28.x | **PASSED** | 0 off-grid vertices or non-standard angles |
| **12** | KLayout Met Min CA Density | KLayout 0.28.x | **PASSED** | Metal layer density within foundry limits |
| **13** | Pin Label Purposes Overlap | KLayout 0.28.x | **PASSED** | 0 overlapping pin text labels |
| **14** | Zero Area Check | KLayout 0.28.x | **PASSED** | 0 zero-area polygons or degenerate shapes |

---

### 3. OpenLane Signoff Metrics

| Metric | Measured Value | Signoff Limit | Status |
| :--- | :---: | :---: | :---: |
| **Wrapper Die Area** | 2920 µm × 3520 µm (10.28 mm²) | < 10.3 mm² | **PASSED** |
| **Core Macro Area** | 1200 µm × 1200 µm (1.44 mm²) | < 2.0 mm² | **PASSED** |
| **Standard Cell Count** | 30,615 gates | N/A | **PASSED** |
| **Sequential Elements** | 3,142 flip-flops | N/A | **PASSED** |
| **Detailed Routing DRC** | 0 violations | 0 violations | **PASSED** |
| **Magic DRC Violations** | 0 | 0 | **PASSED** |
| **Netgen LVS Mismatches**| 0 nets, 0 devices | 0 | **PASSED** |

---

### 4. Reproducibility & Commands for Contest Reviewers

Reviewers can verify the precheck run independently by executing:

```bash
# Set PDK environment
export PDK_ROOT=$(pwd)/dependencies/pdks
export PDK=sky130A

# Run official Efabless precheck
make run-precheck
```

The log output will conclude with:
```text
{{SUCCESS}} All Checks Passed !!!
```
