CC=iverilog
SIM=vvp

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

compile: simulation/tb_Controller.v
	$(CC) -o ctrl.out $(IVARG) simulation/$(TOPMODULE).v

simulation: ctrl.out
	$(SIM) ctrl.out