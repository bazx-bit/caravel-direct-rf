# PCBA Evaluation Plan & Pin Map
## Cognitive Direct-RF Sampling Transceiver — Caravel QFN-64 Breakout Board

---

### 1. Target Silicon Package
- **Package:** QFN-64 (9mm x 9mm, 0.5mm pitch)
- **Silicon Die:** Caravel SoC with `user_project_wrapper` containing `phase_099_top_integration` Direct-RF DSP macro
- **Fabrication Shuttle:** ChipFoundry chipIgnite (Target: September or December 2026 shuttle)

---

### 2. Complete Pin Map

#### 2.1 RF ADC Input Pins (16-bit I-Channel)
| QFN Pin | Caravel GPIO | Signal Name | Direction | Mode |
| :---: | :---: | :--- | :---: | :--- |
| 13 | GPIO[5] | `adc_i[0]` (LSB) | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 14 | GPIO[6] | `adc_i[1]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 15 | GPIO[7] | `adc_i[2]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 16 | GPIO[8] | `adc_i[3]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 17 | GPIO[9] | `adc_i[4]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 18 | GPIO[10] | `adc_i[5]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 19 | GPIO[11] | `adc_i[6]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 20 | GPIO[12] | `adc_i[7]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 21 | GPIO[13] | `adc_i[8]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 22 | GPIO[14] | `adc_i[9]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 23 | GPIO[15] | `adc_i[10]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 24 | GPIO[16] | `adc_i[11]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 25 | GPIO[17] | `adc_i[12]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 26 | GPIO[18] | `adc_i[13]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 27 | GPIO[19] | `adc_i[14]` | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |
| 28 | GPIO[20] | `adc_i[15]` (MSB) | INPUT | `GPIO_MODE_USER_STD_INPUT_NOPULL` |

#### 2.2 RF DAC Output Pins (16-bit I-Channel)
| QFN Pin | Caravel GPIO | Signal Name | Direction | Mode |
| :---: | :---: | :--- | :---: | :--- |
| 29 | GPIO[21] | `dac_i[0]` (LSB) | OUTPUT | `GPIO_MODE_USER_STD_OUTPUT` |
| 30 | GPIO[22] | `dac_i[1]` | OUTPUT | `GPIO_MODE_USER_STD_OUTPUT` |
| ... | ... | ... | OUTPUT | `GPIO_MODE_USER_STD_OUTPUT` |
| 44 | GPIO[36] | `dac_i[15]` (MSB) | OUTPUT | `GPIO_MODE_USER_STD_OUTPUT` |

#### 2.3 Status & Control
| QFN Pin | Caravel GPIO | Signal Name | Direction | Mode |
| :---: | :---: | :--- | :---: | :--- |
| 45 | GPIO[37] | `chip_ready_out` | OUTPUT | `GPIO_MODE_USER_STD_OUTPUT` |

#### 2.4 Caravel System Pins
| QFN Pin | Signal | Description |
| :---: | :--- | :--- |
| 1 | `VDDA1` | 3.3V Analog Power |
| 2 | `VCCD1` | 1.8V Digital Core Power |
| 3 | `VSSA1` | Analog Ground |
| 4 | `VSSD1` | Digital Ground |
| 5 | `clock` | 40 MHz External Crystal Oscillator |
| 6 | `resetb` | Active-Low System Reset (Active LOW) |
| 7-12 | `flash_*` | SPI Flash Interface (Firmware Storage) |

---

### 3. Clock & Reset Wiring

```
 [40 MHz Crystal]
        │
        ▼
 ┌─────────────┐      ┌──────────────────────────────────────┐
 │ clock (pin5) │─────►│ Caravel Management SoC PLL            │
 └─────────────┘      │   │                                    │
                      │   ├──► wb_clk_i ──► clk_dsp (DSP Core)│
                      │   └──► user_clock2 (optional 2nd clk) │
                      └──────────────────────────────────────┘

 [RC Debounce + Pull-up]
        │
        ▼
 ┌──────────────┐
 │ resetb (pin6)│─────► Caravel rst_n (Active LOW)
 └──────────────┘
```

- **Primary Clock:** External 40 MHz crystal oscillator connected to Caravel `clock` input. The Caravel PLL synthesizes internal clocks.
- **Reset:** Active-LOW reset with a 10kΩ pull-up to VDD3V3 and a 100nF debounce capacitor.

---

### 4. Power Rails

| Rail | Voltage | Caravel Pin | Purpose | Decoupling |
| :--- | :---: | :--- | :--- | :--- |
| `VDDA1` / `VDDA2` | 3.3V | Analog VDD | I/O pad ring power | 10µF + 100nF per pin |
| `VCCD1` / `VCCD2` | 1.8V | Digital VDD | Core logic + user project | 10µF + 100nF per pin |
| `VDD3V3` / `VDDIO` | 3.3V | I/O VDD | GPIO pad drivers | 10µF + 100nF per pin |
| `VSS*` | 0V | All grounds | Tied to common ground plane | Star ground topology |

---

### 5. ADC/DAC Loopback Test Plan (Post-Silicon)

#### 5.1 Digital Loopback Test (No External RF Hardware Required)
1. Connect DAC output pins (GPIO 21–36) directly back to ADC input pins (GPIO 5–20) via 16 jumper wires on the breakout board.
2. Program the DSP core to output a known digital test pattern (e.g., a sinusoidal LUT sweep) on the DAC.
3. Read back the ADC input pins and verify bit-exact match with the transmitted pattern.
4. **Expected Result:** Zero bit errors confirms the GPIO interface, shift register, and DSP datapath are functional on physical silicon.

#### 5.2 External RF Loopback Test (With Lab Equipment)
1. Connect a waveform generator (e.g., Keysight 33600A) to the ADC input pins via a parallel-to-SMA adapter board.
2. Drive a known 1 MHz / 10 MHz / 100 MHz digital sine pattern into the ADC inputs.
3. Monitor the DAC output pins on a logic analyzer (e.g., Saleae Logic Pro 16) or oscilloscope.
4. **Expected Result:** The DSP filters the input and produces a clean baseband output on the DAC pins, verifiable against the Python golden model reference waveforms.

---

### 6. Required Instrumentation
| Equipment | Model (Example) | Purpose |
| :--- | :--- | :--- |
| Logic Analyzer | Saleae Logic Pro 16 | Capture 16-bit parallel DAC output waveforms |
| Oscilloscope | Rigol DS1054Z / Keysight DSOX | Verify clock integrity and signal timing |
| Power Supply | Keithley 2231A-30-3 | Supply 3.3V and 1.8V rails with current monitoring |
| Waveform Generator | Keysight 33600A | Drive digital test patterns into ADC inputs |
| Multimeter | Fluke 87V | Verify power rail voltages and quiescent current |
