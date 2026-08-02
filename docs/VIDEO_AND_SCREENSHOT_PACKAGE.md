# Contest Video and Screenshot Package

## Three-minute sequence

| Time | Demonstration |
|---|---|
| 0:00-0:20 | Problem: reproducible low-cost direct-RF DSP/control prototype. |
| 0:20-0:45 | Show `verilog/rtl/user_project_wrapper.v` and macro connection. |
| 0:45-1:15 | Show the C firmware and gate-level testbench. Explain terminal failure handling. |
| 1:15-1:45 | Run documented RTL and gate-level verification commands. |
| 1:45-2:15 | Show OpenLane GDS, DEF, LEF, SDF/SPEF, and timing outputs. |
| 2:15-2:40 | Open the official precheck log and show the final success line. |
| 2:40-3:00 | State the boundary: Sky130 pre-silicon evidence; RF results follow fabrication. |

## Screenshots to Capture

Capture these from the clean submission checkout under
`docs/source/_static/submission/`:

1. `01_repository_structure.png` - clean package tree.
2. `02_wrapper_rtl.png` - wrapper instantiating the RF macro.
3. `03_firmware_test.png` - firmware and Verilog testbench.
4. `04_gds_layout.png` - GDS/layout viewer showing `user_project_wrapper`.
5. `05_openlane_views.png` - final GDS/DEF/LEF/SDF/SPEF outputs.
6. `06_precheck_success.png` - terminal/log with the final success line.
7. `07_pcba_schematic.png` - KiCad schematic opened from `pcb/`.
8. `08_mechanical_concept.png` - rendered `mechanicals/enclosure_spec.scad`.

Do not create screenshots that imply fabricated silicon or measured RF results.
The precheck screenshot must show the command/log source and timestamp.

## Current Asset Status

- PCBA schematic: `pcb/rf_transceiver_breakout.kicad_sch` present.
- Mechanical concept: `mechanicals/enclosure_spec.scad` present.
- Video script: `docs/CONTEST_VIDEO_SCRIPT.md` present.
- Official precheck log: `precheck_results/28_JUL_2026___09_55_48/logs/precheck.log`.
- Actual video and final screenshots still need to be captured from the clean checkout.

