#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
# SPDX-License-Identifier: Apache-2.0
"""
Caravel Design Verification (DV) Runner for Windows Docker Desktop Environment

This script launches the Efabless DV Docker container with all necessary
volume mounts for Caravel GL, management-core GL, and Sky130 cvc-pdk
primitive models to compile and simulate the rf_transceiver_test firmware.
"""

import os
import sys
import subprocess
import argparse


def main():
    parser = argparse.ArgumentParser(description="Caravel DV Docker Simulation Runner")
    parser.add_argument("--test", default="rf_transceiver_test",
                        help="Test pattern directory under verilog/dv")
    parser.add_argument("--sim", default="RTL", choices=["RTL", "GL", "GL_SDF"],
                        help="Simulation mode")
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    # Verify critical paths exist
    caravel_dir = os.path.join(project_root, "caravel")
    mcw_dir = os.path.join(project_root, "mgmt_core_wrapper")
    test_dir = os.path.join(project_root, "verilog", "dv", args.test)

    for d, label in [(caravel_dir, "caravel"), (mcw_dir, "mgmt_core_wrapper"), (test_dir, "test dir")]:
        if not os.path.isdir(d):
            print(f"[ERROR] Missing {label} at: {d}")
            sys.exit(1)

    print("=" * 74)
    print(" Caravel Design Verification Runner")
    print(f" Target Test:       {args.test}")
    print(f" Simulation Mode:   {args.sim}")
    print(f" Project Directory: {project_root}")
    print("=" * 74)

    # Container paths (POSIX)
    c_proj = "/work"
    c_test = f"{c_proj}/verilog/dv/{args.test}"

    # Efabless DV container tool paths
    tools_iverilog = "/foss/tools/iverilog/cc0a8c8dd2fef69c4f7fb8219542b1c03a71a3b4/bin"
    tools_gcc = "/foss/tools/riscv-gnu-toolchain-rv32i/217e7f3debe424d61374d31e33a091a630535937/bin"
    path_env = f"{tools_iverilog}:{tools_gcc}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    docker_cmd = [
        "docker", "run", "--rm",
        "-v", f"{project_root}:{c_proj}",
        "-e", f"CARAVEL_ROOT={c_proj}/caravel",
        "-e", f"MCW_ROOT={c_proj}/mgmt_core_wrapper",
        "-e", f"USER_PROJECT_VERILOG={c_proj}/verilog",
        "-e", f"PDK=sky130A",
        "-e", f"SIM={args.sim}",
        "-e", f"PATH={path_env}",
        "-w", c_test,
        "efabless/dv:latest",
        "sh", "-c", "make clean && make hex && make"
    ]

    print(f"\n[INFO] Launching Docker container...")
    print(f"[EXEC] {' '.join(docker_cmd)}\n")

    try:
        proc = subprocess.run(docker_cmd)
        if proc.returncode == 0:
            print("\n[SUCCESS] Simulation completed successfully!")
        else:
            print(f"\n[INFO] Simulation exited with code {proc.returncode}")
    except Exception as e:
        print(f"[ERROR] Failed to run Docker command: {e}")


if __name__ == "__main__":
    main()
