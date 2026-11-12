#!/bin/bash
# ============================================================================
# run.sh -- assemble the programs, compile, and run every test.
# Usage (from inside the project folder):   ./run.sh
# Needs: Icarus Verilog (iverilog, vvp) and python3.
# ============================================================================
set -e                       # stop at the first error
cd "$(dirname "$0")"         # always run from the project folder
mkdir -p build               # compiled files, traces and waveforms go here

COMMON="src/building_blocks.v src/regfile.v src/memory.v src/alu.v"

echo "---- 0. Assemble the test programs ----"
for p in mipstest test2 test3 factorial fibonacci; do
    out=programs/$p.dat
    [ $p = mipstest ] && out=programs/memfile.dat
    python3 tools/masm.py programs/$p.asm $out > /dev/null
done
echo "programs/*.dat are up to date"

echo
echo "---- 1. ALU (Lab 5 + 6) ----"
iverilog -Wall -o build/alu.vvp tb/tb_alu.v src/alu.v
vvp -n build/alu.vvp

echo
echo "---- 2. Single-cycle MIPS (Lab 8) ----"
iverilog -Wall -o build/mips.vvp \
    tb/tb_top.v src/top.v src/mips.v src/controller.v src/datapath.v $COMMON
vvp -n build/mips.vvp

echo
echo "---- 3. Extended MIPS with ori + bne (Lab 9) ----"
iverilog -Wall -o build/lab9.vvp \
    lab9/tb_lab9.v src/top.v lab9/mips.v lab9/controller.v lab9/datapath.v $COMMON
vvp -n build/lab9.vvp

echo
echo "---- 4. 19-instruction core (andi slti lui sll srl jal jr) ----"
# name:expected value of the final store to address 84
for t in test3:0001670C factorial:000002D0 fibonacci:00000058; do
    name=${t%%:*}; expected=${t##*:}
    iverilog -Wall -o build/$name.vvp \
        -DPROGRAM="\"programs/$name.dat\"" -DTRACE="\"build/$name.trace\"" \
        -DWAVES="\"build/$name.vcd\"" -DEXPECTED="32'h$expected" \
        extended/tb_extended.v src/top.v extended/mips.v extended/controller.v extended/datapath.v $COMMON
    vvp -n build/$name.vvp | grep -v "VCD info"
    # Co-simulation: the hardware trace must equal the software model's trace.
    python3 tools/mipssim.py programs/$name.dat > build/$name.golden
    if diff -q build/$name.trace build/$name.golden > /dev/null; then
        echo "Trace matches the software model: $(wc -l < build/$name.trace | tr -d ' ') register and memory writes identical."
    else
        echo "Trace DIFFERS from the software model: see build/$name.trace and build/$name.golden"
        exit 1
    fi
done

echo
echo "Done. Open the waveforms with:   surfer build/mips.vcd"
