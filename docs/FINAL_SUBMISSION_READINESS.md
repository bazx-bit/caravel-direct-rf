# Final Submission Readiness

## What Is Complete

- Caravel-style `user_project_wrapper` integration.
- Sky130 OpenLane physical-design artifacts: GDS, DEF, LEF, gate-level netlist,
  SDF, SPEF, and SDC.
- Official MPW precheck result with all checks passing in the recorded run.
- RTL and gate-level testbench sources.
- Caravel management-SoC firmware self-test source.
- PCBA and post-silicon validation plans.
- Apache-2.0 licensing and package checksums.

## Evidence Boundary

This is a pre-silicon Sky130 digital/DSP prototype. It does not yet prove
fabricated RF performance, 2.4 GSps operation, ENOB, SNR, SFDR, temperature,
or measured power. The 2.4 GSps statement is a future architecture target;
the Sky130 result must be described using its actual timing constraints and
later silicon measurements.

## Required Before Upload

1. Select the exact ChipFoundry shuttle and read its current submission rules.
2. Confirm the applicable area definition. The Caravel wrapper floorplan is
   2920 x 3520 um (about 10.28 mm2); do not label this as a 10 mm2 design
   without confirming whether the shuttle limit applies to the user area or
   the complete wrapper.
3. Include the exact precheck log and tool/PDK version manifest.
4. Include the firmware test and gate-level testbench paths in the submission
   README.
5. Include the PCBA and post-silicon validation plans if the contest requires
   a complete reference design.
6. Package AI prompts/session logs only in the form and location required by
   the current contest rules; do not claim a transcript file is included
   unless it is actually present in the submitted archive.
7. Review the detailed wrapper STA slew warnings and attach the waiver with
   the exact report names and scope.

## Correct Submission Description

> Caravel-integrated Sky130 direct-RF DSP/control prototype with generated
> physical-design views and a successful official MPW precheck. RF silicon
> performance and post-silicon measurements remain future work.

## Do Not Claim Yet

- Fabricated silicon success.
- 2.4 GSps Sky130 operation.
- Measured RF ENOB, SNR, SFDR, power, or temperature.
- Production-ready transceiver performance.
