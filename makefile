CC=iverilog
SIM=vvp
LINT=verilator

TOPMODULE=tb_Controller
IVARG = -g2001
IVARG += -D SIMPLE_REPORT
IVARG += -D DEBUG
IVARG += -I hdl/include/
IVARG += -I testbench/
IVARG += -I hdl/src/
IVARG += -s $(TOPMODULE)
# IVARG += hdl/src/Controller.v
# IVARG += hdl/include/global_define.vh
# IVARG += simulation/tb_Controller.v

VVARG = --lint-only
VVARG += -Wall
VVARG += -Wno-STMTDLY
VVARG += --language 1364-2005
VVARG += -Ihdl/include/
VVARG += -Itestbench/
VVARG += -Ihdl/src/
VVARG += --top-module $(TOPMODULE)

compile: testbench/$(TOPMODULE).v
	$(CC) -o ctrl.out $(IVARG) testbench/$(TOPMODULE).v

simulation: ctrl.out
	$(SIM) ctrl.out

lint: testbench/$(TOPMODULE).v
	$(LINT) $(VVARG) testbench/$(TOPMODULE).v