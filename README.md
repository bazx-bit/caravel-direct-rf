# Cognitive Direct-RF Sampling Transceiver ?" Caravel MPW Submission

<div align="center">
  <img src="hero_image.png" alt="Cognitive RF Transceiver Silicon Layout" width="800" />
</div>

<p align="center">
  <b>100-Phase Digital SDR Baseband & DSP Engine</b> implemented on the SkyWater 130nm Open-Source PDK.
</p>

---

> [!IMPORTANT]
> **Architectural Scope & Honest Pre-Tapeout Disclosure:**
> This design is a **pure digital CMOS DSP Engine** (`sky130_fd_sc_hd`). The ADC/DAC interfaces are 16-bit digital buses (`io_in`/`io_out`) designed to interface with external ultra-high-speed converters on the PCB. The 2.4 GSps direct-RF specification represents the mathematical target architecture for a future SiGe BiCMOS port; this Sky130 implementation is expected to operate at standard digital logic clock speeds (~50?"100 MHz) until silicon validation is performed. No RF ENOB, SNR, or physical power metrics are claimed prior to fabrication.

## 1. Project Overview

The **Cognitive Direct-RF Transceiver** is a massively pipelined digital signal processing (DSP) core designed for next-generation Software Defined Radios. Hardened as a single macro (`phase_099_top_integration`) and fully integrated into the Efabless Caravel harness, it implements 100 sequential verification phases of advanced communications IP.

### Key Specifications

| Parameter | Specification | Implementation Details |
|-----------|---------------|------------------------|
| **PDK Target** | SkyWater 130nm | `sky130_fd_sc_hd` high-density standard cells |
| **Macro Area** | 1200 µm × 1200 µm | Dense DSP routing, OpenLane hardened |
| **Wrapper Area** | 2920 µm × 3520 µm | Standard Caravel `user_project_wrapper` |
| **Logic Density** | 30,615 Gates | Pipelined arithmetic, multiply-accumulate |
| **State Elements** | 3,142 Flip-Flops | Deep pipeline registers for high-speed $f_{max}$ |
| **Verification** | 491 Pytest Suites | 100% Zero-Regression passing status |
| **Signoff Status** | Efabless Precheck | 14/14 checks passed (DRC/LVS/STA clean) |

## 2. Caravel Integration & Architecture

### System Integration Flow

```mermaid
graph TB
    subgraph CARAVEL["🚀 Caravel SoC Harness"]
        MGMT_CORE[Management Core<br/>PicoRV32 RISC-V]
        MGMT_BUS[Management<br/>Wishbone Bus]
        LA_PROBES[Logic Analyzer<br/>128-bit Probes]
    end
    
    subgraph USER_PROJECT["User Project Wrapper"]
        subgraph DSP_CORE["100-Phase DSP Engine"]
            AXI[AXI-Lite Config]
            NPU[Cognitive NPU]
            FFT[FFT/IFFT Core]
            DPD[Digital Predistortion]
            MOD[QAM Mod/Demod]
        end
        
        MGMT_IF[Wishbone<br/>Slave Interface]
    end
    
    subgraph IO_PADS["Physical I/O Pads"]
        ADC_PADS[ADC Data 16-bit]
        DAC_PADS[DAC Data 16-bit]
        CLK_PAD[External RF Clock]
    end
    
    MGMT_CORE --> MGMT_BUS
    MGMT_BUS -->|Register Config| MGMT_IF
    MGMT_IF -->|Bus Master| AXI
    
    AXI --> NPU
    AXI --> FFT
    AXI --> DPD
    
    ADC_PADS -->|io_in| DSP_CORE
    DSP_CORE -->|io_out| DAC_PADS
    CLK_PAD -->|user_clock2| DSP_CORE
    
    DSP_CORE -->|Status Flags| LA_PROBES
    
    style MGMT_CORE fill:#fff4e1,stroke:#d4a373,stroke-width:2px
    style DSP_CORE fill:#e1f5ff,stroke:#0077b6,stroke-width:2px
    style NPU fill:#ffe1e1,stroke:#d00000
    style FFT fill:#e1ffe1,stroke:#2b9348
    style DPD fill:#e1ffe1,stroke:#2b9348
    style MGMT_IF fill:#f0e1ff,stroke:#5a189a
```

### Internal DSP Pipeline

```mermaid
flowchart LR
    IN[ADC Input] --> DDC[Digital Down Converter]
    DDC --> AGC[Auto Gain Control]
    AGC --> CORDIC[CORDIC Rotator]
    CORDIC --> FFT[FFT Engine]
    FFT --> QAM[QAM Demapper]
    QAM --> FEC[Viterbi Decoder]
    FEC --> OUT[Data Out]
    
    style IN fill:#333,color:#fff
    style OUT fill:#333,color:#fff
```

## 3. Directory & Artifact Structure

```text
caravel_user_project/
├── gds/                    # Final GDSII geometric layouts
│   ├── user_project_wrapper.gds    (86.63 MB)
│   └── phase_099_top_integration.gds (85.32 MB)
├── def/                    # DEF floorplans & routing
├── lef/                    # LEF macro abstracts
├── verilog/
│   ├── rtl/                # 100 Phases of Synthesizable SystemVerilog
│   ├── gl/                 # Post-synthesis gate-level netlists
│   └── dv/                 # Cocotb and C firmware testbenches
├── openlane/               # OpenLane ASIC build configurations
│   └── user_project_wrapper/
├── signoff/                # KLayout DRC, Netgen LVS, OpenROAD STA logs
├── pcb/                    # KiCad Evaluation Board designs
└── info.yaml               # Efabless machine-readable metadata
```

## 4. Hardware Evaluation & PCB Integration

To validate the macro post-silicon, we have designed a high-speed testbench PCBA in KiCad. The board interfaces the Caravel breakout with external ADCs and DACs to test the digital loops.

<div align="center">
  <img src="docs/kicad_hero.svg" alt="KiCad PCB Layout" width="600" />
</div>

- **Firmware Test:** The PicoRV32 management SoC firmware self-test is located at `verilog/dv/rf_transceiver_test/rf_transceiver_test.c`. It accesses the AXI-Lite registers over the Wishbone bus.
- **Logic Analyzer:** The 128-bit Caravel Logic Analyzer probes are mapped to the internal DSP state machines for real-time silicon debugging.

## 5. Verification & Zero-Regression Discipline

This repository adheres to a strict **Zero-Regression Protocol**. Every module from Phase 001 to Phase 100 is verified against a bit-accurate Python Golden Model.

1. `tests/` executes 491 Pytest assertions against the SystemVerilog RTL.
2. `make run-precheck` confirms absolute compliance with Efabless MPW constraints.
3. OpenROAD multicorner STA guarantees setup/hold closure across min/nom/max corners.

---
**License:** SPDX-License-Identifier: Apache-2.0
