CC=iverilog
SIM=vvp
LINT=verilator

TOPMODULE=tb_Controller
IVARG = -g2001
IVARG += -D SIMPLE_REPORT
IVARG += -D DEBUG
IVARG += -I hdl/include/
IVARG += -I simulation/
IVARG += -I hdl/src/
IVARG += -s $(TOPMODULE)
# IVARG += hdl/src/Controller.v
# IVARG += hdl/include/global_define.vh
# IVARG += simulation/tb_Controller.v

VVARG = --lint-only
VVARG += -Wall
VVARG += --language 1364-2005
VVARG += -Ihdl/include/
VVARG += -Isimulation/
VVARG += -Ihdl/src/
VVARG += --top-module $(TOPMODULE)

compile: simulation/$(TOPMODULE).v
	$(CC) -o ctrl.out $(IVARG) simulation/$(TOPMODULE).v

simulation: ctrl.out
	$(SIM) ctrl.out

lint: simulation/$(TOPMODULE).v
	$(LINT) $(VVARG) simulation/$(TOPMODULE).v