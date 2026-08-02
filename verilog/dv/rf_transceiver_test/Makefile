# SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
# SPDX-License-Identifier: Apache-2.0
#
# Caravel DV Makefile for rf_transceiver_test

PWDD = $(shell pwd)
PATTERN = rf_transceiver_test
SIM ?= RTL

# Sky130 PDK simulation primitives from cvc-pdk (standard cells, I/O, SRAM)
PDK_SIM_SOURCES = \
	$(MCW_ROOT)/verilog/cvc-pdk/primitives_hd.v \
	$(MCW_ROOT)/verilog/cvc-pdk/primitives_hvl.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_ef_io.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_ef_io__analog_pad.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_fd_io.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_fd_sc_hd.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_fd_sc_hvl.v \
	$(MCW_ROOT)/verilog/cvc-pdk/sky130_sram_2kbyte_1rw1r_32x512_8.v

# Management Core RTL Sources
MCW_RTL_SOURCES = \
	$(MCW_ROOT)/verilog/rtl/defines.v \
	$(MCW_ROOT)/verilog/rtl/mgmt_core_wrapper.v \
	$(MCW_ROOT)/verilog/rtl/mgmt_core.v \
	$(MCW_ROOT)/verilog/rtl/VexRiscv_MinDebugCache.v \
	$(MCW_ROOT)/verilog/rtl/picorv32.v \
	$(MCW_ROOT)/verilog/rtl/ibex_all.v \
	$(MCW_ROOT)/verilog/rtl/RAM128.v \
	$(MCW_ROOT)/verilog/gl/RAM256.v

# ---------- Build Targets ----------

all: $(PATTERN).vcd

hex:  $(PATTERN).hex

# Default compiler flags
IVERILOG_FLAGS = -g2012 -Ttyp -DSIM -DFUNCTIONAL -DUSE_POWER_PINS \
	-DMPRJ_IO_PADS=38 -DMPRJ_IO_PADS_1=19 -DMPRJ_IO_PADS_2=19 \
	-I $(CARAVEL_ROOT)/verilog/rtl \
	-I $(CARAVEL_ROOT)/verilog/dv/caravel \
	-I $(MCW_ROOT)/verilog/rtl \
	-I $(MCW_ROOT)/verilog/cvc-pdk \
	-I $(USER_PROJECT_VERILOG)/rtl \
	-I $(USER_PROJECT_VERILOG)/gl

# Simulation-specific sources
ifeq ($(SIM),RTL)
	IVERILOG_FLAGS += -DFUNCTIONAL
	# In RTL mode we must explicitly list the Caravel SoC RTL models 
	# and we include PDK sources because phase_099 is gate-level.
	CARAVEL_SOURCES = \
		$(CARAVEL_ROOT)/verilog/rtl/defines.v \
		$(CARAVEL_ROOT)/verilog/rtl/pads.v \
		$(CARAVEL_ROOT)/verilog/rtl/__user_project_wrapper.v \
		$(CARAVEL_ROOT)/verilog/rtl/caravel.v \
		$(CARAVEL_ROOT)/verilog/rtl/caravel_core.v \
		$(CARAVEL_ROOT)/verilog/rtl/digital_pll.v \
		$(CARAVEL_ROOT)/verilog/rtl/housekeeping.v \
		$(CARAVEL_ROOT)/verilog/rtl/gpio_control_block.v \
		$(CARAVEL_ROOT)/verilog/rtl/gpio_defaults_block.v \
		$(CARAVEL_ROOT)/verilog/rtl/gpio_logic_high.v \
		$(CARAVEL_ROOT)/verilog/rtl/xres_buf.v \
		$(CARAVEL_ROOT)/verilog/rtl/spare_logic_block.v \
		$(CARAVEL_ROOT)/verilog/rtl/clock_div.v \
		$(CARAVEL_ROOT)/verilog/rtl/ring_osc2x13.v \
		$(CARAVEL_ROOT)/verilog/rtl/chip_io.v \
		$(CARAVEL_ROOT)/verilog/rtl/mgmt_protect.v \
		$(CARAVEL_ROOT)/verilog/rtl/mgmt_protect_hv.v \
		$(CARAVEL_ROOT)/verilog/rtl/mprj_io.v \
		$(CARAVEL_ROOT)/verilog/rtl/simple_por.v \
		$(CARAVEL_ROOT)/verilog/rtl/caravel_clocking.v \
		$(CARAVEL_ROOT)/verilog/rtl/caravel_logo.v \
		$(CARAVEL_ROOT)/verilog/rtl/caravel_motto.v \
		$(CARAVEL_ROOT)/verilog/rtl/constant_block.v \
		$(CARAVEL_ROOT)/verilog/rtl/copyright_block.v \
		$(CARAVEL_ROOT)/verilog/rtl/debug_regs.v \
		$(CARAVEL_ROOT)/verilog/rtl/digital_pll_controller.v \
		$(CARAVEL_ROOT)/verilog/rtl/empty_macro.v \
		$(CARAVEL_ROOT)/verilog/rtl/housekeeping_spi.v \
		$(CARAVEL_ROOT)/verilog/rtl/manual_power_connections.v \
		$(CARAVEL_ROOT)/verilog/rtl/mprj2_logic_high.v \
		$(CARAVEL_ROOT)/verilog/rtl/mprj_io_buffer.v \
		$(CARAVEL_ROOT)/verilog/rtl/mprj_logic_high.v \
		$(CARAVEL_ROOT)/verilog/rtl/open_source.v \
		$(CARAVEL_ROOT)/verilog/rtl/user_id_programming.v \
		$(CARAVEL_ROOT)/verilog/rtl/user_id_textblock.v \
		$(MCW_RTL_SOURCES) \
		$(PDK_SIM_SOURCES)
else
	# GL Mode
	IVERILOG_FLAGS += -DGL -DFUNCTIONAL
	CARAVEL_SOURCES = \
		$(CARAVEL_ROOT)/verilog/rtl/defines.v \
		$(CARAVEL_ROOT)/verilog/dv/caravel/sky130_fd_sc_hd_stub.v \
		$(filter-out $(CARAVEL_ROOT)/verilog/gl/caravan% \
			$(CARAVEL_ROOT)/verilog/gl/chip_io_alt% \
			$(CARAVEL_ROOT)/verilog/gl/housekeeping_alt% \
			$(CARAVEL_ROOT)/verilog/gl/__%, \
			$(wildcard $(CARAVEL_ROOT)/verilog/gl/*.v)) \
		$(wildcard $(MCW_ROOT)/verilog/gl/*.v) \
		$(PDK_SIM_SOURCES)
endif

$(PATTERN).vcd: $(PATTERN).hex
	iverilog $(IVERILOG_FLAGS) \
		-o $@.vvp $(PATTERN)_tb.v \
		$(CARAVEL_ROOT)/verilog/dv/caravel/spiflash.v \
		$(USER_PROJECT_VERILOG)/rtl/user_defines.v \
		$(USER_PROJECT_VERILOG)/gl/phase_099_top_integration.v \
		$(CARAVEL_SOURCES)
	vvp $@.vvp | tee $(PATTERN).log

%.elf: %.c
	riscv32-unknown-linux-gnu-gcc \
		-I$(CARAVEL_ROOT)/verilog/dv/caravel \
		-I$(CARAVEL_ROOT)/verilog/dv/caravel/defs \
		-O2 -mabi=ilp32 -march=rv32i -D__vexriscv__ \
		-Wl,-Bstatic,-T,$(CARAVEL_ROOT)/verilog/dv/caravel/sections.lds,--strip-debug \
		-ffreestanding -nostdlib -o $@ $<

%.hex: %.elf
	riscv32-unknown-linux-gnu-objcopy -O verilog $< $@
	sed -i 's/@10000000/@00000000/g' $@

clean:
	rm -f *.elf *.hex *.vvp *.vcd *.log

.PHONY: all hex clean
