VERILATOR ?= verilator
RTL := rtl/mac_pe.sv
TB := tb/tb_mac_pe.sv
COMMON_FLAGS := --binary --timing --assert -Wall -Wno-fatal --top-module tb_mac_pe

.PHONY: lint test wave clean

lint:
	$(VERILATOR) --lint-only -Wall --top-module mac_pe $(RTL)

test:
	mkdir -p build/obj_dir
	$(VERILATOR) $(COMMON_FLAGS) --Mdir build/obj_dir $(RTL) $(TB)
	./build/obj_dir/Vtb_mac_pe +verilator+seed+189

wave:
	mkdir -p build
	$(VERILATOR) $(COMMON_FLAGS) --trace --Mdir build/obj_wave $(RTL) $(TB)
	./build/obj_wave/Vtb_mac_pe +verilator+seed+189 +trace

clean:
	rm -rf build
