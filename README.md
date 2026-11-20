# Sparse-Aware Systolic Array Accelerator

A SystemVerilog RTL implementation of a **2×2 output-stationary systolic array** for matrix multiplication, using signed **INT8 operands** and **INT32 accumulation**. The project explores zero-operand suppression and cycle-accurate verification of the accelerator datapath.

### Dataflow Visualization

$$
A = \begin{bmatrix}
1 & 0 & 2 \\
3 & 1 & 1 \\
2 & 2 & 1
\end{bmatrix}


B = \begin{bmatrix}
2 & 1 & 1 \\
1 & 3 & 0 \\
1 & 2 & 2
\end{bmatrix}

$$

$$
C = A \times B =
\begin{bmatrix}
4 & 5 & 5 \\
8 & 8 & 5 \\
7 & 10 & 4
\end{bmatrix}
$$

The three matrices show side by side with brackets. Other viewers, like some editors or npm, may not render LaTeX. If you need it to look right everywhere, this plain code-block version works anywhere:

<p align="center">
  <img
    src="docs/systolic-array.svg"
    alt="2×2 output-stationary systolic array"
    width="580"
  />
</p>

<p align="center">
  <sub>
    <em>
      Output-stationary dataflow: A propagates horizontally,
      B vertically, and partial sums accumulate locally.
    </em>
  </sub>
</p>

## Architecture

- **Parameterized MAC processing element:** Configurable operand and accumulator widths, with local accumulation and operand forwarding.
- **2×2 systolic array:** Matrix A propagates horizontally and matrix B vertically; each PE retains its partial sum.
- **Pipeline control:** Validity propagation, global `step`/stall control, synchronous reset, and accumulator clearing.
- **Sparse mode:** Isolates multiplier operands and skips accumulator updates for zero products while preserving results and execution timing. Power savings have not yet been measured.

## Verification

- **PE-level SystemVerilog testbench:** Self-checking reference model covering signed arithmetic, reset, stalls, validity, and dense/sparse equivalence (12 directed cases + 1,000 randomized cycles).
- **Array-level SystemVerilog testbench:** Checks forwarding, stalls, and 2×2 matrix multiplication, including 100 randomized matrix pairs in both dense and sparse modes.
- **UVM environment (in development):** Randomized GEMM transactions, driver, monitor, and reference-model scoreboard. Not yet integrated into the default Makefile flow.

## Build and Run

Requires **Verilator 5.x**, **GNU Make**, and a **C++ compiler**.

```bash
# Lint and run the processing-element testbench
make lint
make test

# Optional: generate build/pe_wave.vcd
make wave
```

Run the 2×2 array testbench separately:

```bash
verilator --binary --timing --assert -Wall -Wno-fatal \
  --top-module tb_systolic_2x2 --Mdir build/array \
  rtl/mac_pe.sv rtl/systolic_2x2.sv tb/tb_systolic_2x2.sv
./build/array/Vtb_systolic_2x2
```

Use `make clean` to remove generated build files.

## Repository Structure

```text
rtl/                  Synthesizable MAC PE and 2×2 array
tb/                   Self-checking SystemVerilog testbenches
verification/uvm/     UVM verification components
formal/               Formal verification work
scripts/              Utility scripts
Makefile              PE lint, simulation, and waveform targets
```

**Current scope:** The PE is parameterized; the array is currently fixed at 2×2. Scalable arrays, formal sign-off, and measured power/area/performance comparisons remain future work.