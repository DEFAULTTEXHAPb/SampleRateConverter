# UPSAMPLER

## About project

This is an digital upsampler design that realise algorithm of multistage polyphase FIR filtering.

## Files

|file    | describtion |
|:-------|:-----------:|
`DPRAM.v`|Block Dual Port RAM
`MAC.v`  |Multiplication and adder unit for vector convolution
`ControlUnit.v`|Control Unit of system with FSM
`AddrCalc.v`|Addres ALU

## TODO

* [x] AudioBus
* [x] RAM
* [x] AddrCalc
* [x] MAC _(there is problem with sign extension of error word)_
* [] Control Unit
* [x] RegFile
* [x] Allocation List Set with Programm Counter
* [] Top-level module
* [] simple testbench
