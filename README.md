# Sparse-Aware Systolic Array Accelerator

An independent, noncommercial RTL-design + verification portfolio project.

> **Status: Work in Progress (WIP)**

An RTL implementation of a parameterized systolic array for matrix multiplication, exploring sparse computation, operand gating, and hardware efficiency.

## Overview

This project explores the design of a systolic array composed of multiply-accumulate (MAC) Processing Elements (PEs).

The architecture uses an output-stationary dataflow, where operands propagate between neighboring PEs while partial sums are accumulated locally.

A primary focus is investigating how sparsity-aware optimizations can reduce unnecessary switching activity and improve energy efficiency.

## Architecture

Each PE supports the following design concepts:

- **Multiply-Accumulate (MAC):** Signed multiplication with a wider accumulator.
- **Operand Forwarding:** A operands propagate horizontally and B operands vertically.
- **Validity Propagation:** Valid signals distinguish meaningful operands from pipeline bubbles.
- **Global Step Control:** Enables synchronized pipeline advancement and stalling.
- **Sparse Operand Gating:** Forces local multiplier operands to zero when either input is zero, without modifying forwarded data.

## Development Roadmap

- [ ] Complete parameterized MAC PE implementation
- [ ] Implement PE-level functional testbench
- [ ] Build a 2×2 systolic array
- [ ] Extend to configurable array dimensions
- [ ] Implement input skewing and matrix multiplication scheduling
- [ ] Verify dense and sparse workloads
- [ ] Evaluate switching activity and power implications
- [ ] Explore performance and area tradeoffs

## Tools

- SystemVerilog
- RTL simulation and verification
- Waveform analysis

**Milestone 1 (In Progress):** signed INT8 -> INT32 output-stationary multiply-accumulate
processing element (PE), with operand forwarding, reset/clear, global stall,
dense and zero-suppressed modes, and a self-checking SV testbench.

## Prerequisites

Use a WSL2 Linux terminal or native Linux installation with Verilator 5.x,
GNU Make, and a C++ compiler. The PE-only milestone does not require UVM.
For future full UVM work, prefer Verilator >= 5.052 and check its UVM limitations.

On Ubuntu/WSL, a baseline install may be:

```bash
sudo apt update
sudo apt install -y verilator build-essential make git
verilator --version
```

Distribution packages can lag recent releases. Don't assume an apt version
is new enough for UVM; we will address upgrading separately at milestone 5.

## Quick start

```bash
make lint
make test
make wave
```

- make lint: Checks RTL for coding mistakes and suspicious constructs
- make test: Compiles and simulates the PE with its testbench
- make wave: Simulates the PE and generates waveform
- make clean: Delete generated build files

Expected successful simulation conclusion:
`ALL PE TESTS PASSED: 1012 cycles checked`

The `wave` target creates `build/pe_wave.vcd`; inspect it with GTKWave
(or another VCD-compatible waveform viewer).

The testbench checks the reference accumulated result and forwarded operands
of **both** the dense and the sparse modes after every clock edge.
It includes a dozen directed cases plus 1000 deterministic random cycles.
This starter has NOT been simulator-tested in its creation environment because
Verilator was not installed there. Please run it locally and report any
simulator-version-specific warnings or errors before moving forward.

## Directory structure

- `rtl/`: synthesizable hardware.
- `tb/`: lightweight PE/array tests.
- `verification/uvm/`: future UVM environment.
- `formal/`: future formal properties and proof harnesses.
- `docs/spec.md`: requirements and intended invariants.
- `docs/roadmap.md`: milestone checklist and sign-off criteria.

## Scope of the sparse optimization

Sparse mode isolates the multiplier operands when either input is zero, and
avoids an accumulator register update. It preserves matrix results and
fixed execution timing. This is zero suppression, **not** sparse-data
compression or automatic cycle-count reduction. Any power benefit must be
measured; it is not established just from the RTL.
