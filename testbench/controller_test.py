import os
import os.path as path
import pytest
import cocotb as ctb
import cocotb_test.simulator as tester

class TB(object):
  pass

class MicroBlaze():
  pass


@ctb.test()
def controller_test(dut):
  pass

tests_dir = path.dirname(__file__)
hdl_dir = path.abspath(path.join(tests_dir, '..', 'hdl'))

@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="Verilog not suported")
def test_controller():
  dut = "ctrl_top"
  module = path.splitext(path.basename(__file__))[0]

  parameters = {}

  parameters['DATA_ADDR_WIDTH'] = 5
  parameters['']
  

  verilog_sources = [
      path.join(hdl_dir, f"/controller/{dut}.v")
  ]
  compile_args = [
    "-g2005",
    "-Wall"
  ]
  includes = [
    f"{hdl_dir}/src/",
    f"{hdl_dir}/include/",
  ]
  tester.run(
    verilog_sources = verilog_sources,
    toplevel = dut,
    module = module,
    compile_args = compile_args
  )


# -*- coding: utf-8 -*-
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.regression import TestFactory

@cocotb.test()
async def run_test(dut):
  PERIOD = 10
  cocotb.fork(Clock(dut.clk, PERIOD, 'ns').start(start_high=False))

  dut.rst = 0
  dut.en = 0
  dut.prog = 0
  dut.iw_valid = 0
  dut.load_coef_addr = 0
  dut.instr_word = 0

  await Timer(20*PERIOD, units='ns')

  dut.rst = 1
  dut.en = 1
  dut.prog = 1
  dut.iw_valid = 1
  dut.load_coef_addr = 1
  dut.instr_word = 1
  dut.ptr_req = 1
  dut.en_calc = 1
  dut.mac_init = 1
  dut.en_ram_pa = 1
  dut.en_ram_pb = 1
  dut.wr_ram_pa = 1
  dut.wr_ram_pb = 1
  dut.regf_rd = 1
  dut.regf_wr = 1
  dut.regf_en = 1
  dut.new_in = 1
  dut.new_out = 1
  dut.data_addr = 1
  dut.coef_addr = 1
  dut.ars1 = 1
  dut.ars2 = 1
  dut.ard1 = 1
  dut.ard2 = 1

  await Timer(20*PERIOD, units='ns')

  # Register the test.
  factory = TestFactory(run_test)
  factory.generate_tests()
    