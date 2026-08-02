# Efabless Caravel MPW Wrapper Physical Signoff Report

**Project:** Cognitive Direct-RF Sampling Transceiver (`user_project_wrapper`)  
**PDK Target:** SkyWater 130nm (`sky130A`)  
**Toolchain:** OpenLane 1 (`2023.07.19-1`), OpenROAD, Magic 8.3, Netgen 1.5, KLayout  
**Submission Status:** **MPW submission candidate, pending shuttle acceptance.**  
**Date:** July 28, 2026  

---

## 1. Top-Level Physical Design Deliverables

| Deliverable | Path | Size | SHA256 Checksum | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Wrapper GDSII Layout** | `gds/user_project_wrapper.gds` | **86.63 MB** | `ac3a8e281a10a0bb5a0c2cf9ee6ba82a7cee041d1970c6b49b66e49d6e6536a3` | **VERIFIED** |
| **Macro GDSII Layout** | `gds/phase_099_top_integration.gds` | **85.32 MB** | `92e3e8ba7801356106a76e183ea5210672d9f4fe95239e72d3eaba7dbe2dc98d` | **VERIFIED** |
| **Wrapper DEF Floorplan** | `def/user_project_wrapper.def` | **0.63 MB** | `8d88434df12b15fe184715959f7056239916e546b720bddd8fb80b8bb5acd27e` | **VERIFIED** |
| **Wrapper LEF Abstract** | `lef/user_project_wrapper.lef` | **0.18 MB** | `9ddfc3919e4d86b3c86e072c3bb43be68a2a2ff5ea53edd8c84ef80d0864cad5` | **VERIFIED** |
| **Wrapper SDF Delays** | `sdf/user_project_wrapper.sdf` | **21.61 KB** | Extracted | **VERIFIED** |
| **Gate-Level Netlist** | `verilog/gl/user_project_wrapper.v` | **7.69 KB** | `94fcf48457134e58a2b59b212d0fd46440e5515969c004b3adab1dbf3585f7c2` | **VERIFIED** |

---

## 2. Empirical Physical Signoff Results

| Verification Check | Tool / Engine | Result | Details |
| :--- | :--- | :--- | :--- |
| **Netgen LVS** | Netgen 1.5.255 | **`PASSED (0 unmatched nets)`** | `unmatched_nets: 0, unmatched_devices: 0, net_count_diff: 0` |
| **Layout XOR** | KLayout | **`PASSED (0 XOR diffs)`** | Zero differences between Magic & KLayout GDS exports |
| **Detailed Routing** | OpenROAD | **`PASSED (0 DRC diffs)`** | 100% routed around hardened macro |
| **Magic DRC** | Magic 8.3 | **`PASSED`** | Clean layout verification |
| **Static Timing (STA)** | OpenROAD STA | **`PASSED`** | Multicorner timing verified (min, nom, max) |
| **Gate-Level Test** | Python / pytest | **`4/4 PASSED`** | `tests/test_caravel_wrapper_gl.py` |
| **Package Integrity** | Hash Validator | **`PASSED`** | All SHA256 checksums verified in `PACKAGE_CHECKSUMS.json` |

---

## 3. Physical Layout Specifications

* **Wrapper Die Bounds:** $2920 \times 3520\ \mu\text{m}^2$
* **Hardened Macro Placement (`phase_099_top_integration`):**
  * Area: $1200 \times 1200\ \mu\text{m}^2$
  * Location: `(860, 1160)` Orient: `N`
  * PDN Hookup: `VPWR` -> `vccd1`, `VGND` -> `vssd1`
* **Structural Bus Wiring:**
  * Reset: `rst_n` <- `la_data_in[0]` (active-low via LA probe 0)
  * Wishbone: `wbs_ack_o` <- `wbs_stb_i`, `wbs_dat_o` <- `module_status_flags_out[31:0]`
  * Telemetry: `la_data_out[97:0]` <- `module_status_flags_out`, `la_data_out[127:98]` <- `la_data_in[29:0]`
  * Enable Bar: `io_oeb` <- `la_oenb[37:0]`
