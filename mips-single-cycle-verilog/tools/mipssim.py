#!/usr/bin/env python3
"""mipssim.py -- a software model of the 19-instruction processor.

It runs a .dat program one instruction at a time and prints one line for
every register write ("R 8 12340000") and every memory write ("M 84 0001670c").
The Verilog testbench extended/tb_extended.v writes the same lines, so the two
outputs can be compared with diff: if they are identical, the hardware did
exactly what the instruction set says (co-simulation against a golden model).

Usage:   python3 tools/mipssim.py programs/test3.dat > build/test3.golden
"""
import sys

MASK = 0xFFFFFFFF
MEM_WORDS = 64


def signed(x):
    return x - (1 << 32) if x & 0x80000000 else x


def sext16(x):
    return (x | 0xFFFF0000) if x & 0x8000 else x


def run(path, max_steps=100000):
    imem = [int(line, 16) for line in open(path).read().split()]
    imem += [0] * (MEM_WORDS - len(imem))
    dmem = [0] * MEM_WORDS
    reg = [0] * 32
    pc = 0
    out = []

    def wreg(n, value):
        if n != 0:
            reg[n] = value & MASK
            out.append('R %d %08x' % (n, value & MASK))

    for _ in range(max_steps):
        ins = imem[(pc >> 2) % MEM_WORDS]
        op, rs, rt, rd = ins >> 26, (ins >> 21) & 31, (ins >> 16) & 31, (ins >> 11) & 31
        shamt, funct, imm = (ins >> 6) & 31, ins & 63, ins & 0xFFFF
        a, b = reg[rs], reg[rt]
        nxt = (pc + 4) & MASK

        if op == 0x00:                                   # R-type
            if   funct == 0x20: wreg(rd, a + b)                          # add
            elif funct == 0x22: wreg(rd, a - b)                          # sub
            elif funct == 0x24: wreg(rd, a & b)                          # and
            elif funct == 0x25: wreg(rd, a | b)                          # or
            elif funct == 0x2A: wreg(rd, int(signed(a) < signed(b)))     # slt
            elif funct == 0x00: wreg(rd, b << shamt)                     # sll (also nop)
            elif funct == 0x02: wreg(rd, b >> shamt)                     # srl
            elif funct == 0x08: nxt = a                                  # jr
            else: raise ValueError('unknown funct %02x at pc %x' % (funct, pc))
        elif op == 0x08: wreg(rt, a + sext16(imm))                       # addi
        elif op == 0x0A: wreg(rt, int(signed(a) < signed(sext16(imm))))  # slti
        elif op == 0x0C: wreg(rt, a & imm)                               # andi
        elif op == 0x0D: wreg(rt, a | imm)                               # ori
        elif op == 0x0F: wreg(rt, imm << 16)                             # lui
        elif op == 0x23:                                                 # lw
            adr = (a + sext16(imm)) & MASK
            wreg(rt, dmem[(adr >> 2) % MEM_WORDS])
        elif op == 0x2B:                                                 # sw
            adr = (a + sext16(imm)) & MASK
            dmem[(adr >> 2) % MEM_WORDS] = b
            out.append('M %d %08x' % (adr, b))
        elif op == 0x04:                                                 # beq
            if a == b: nxt = (pc + 4 + (sext16(imm) << 2)) & MASK
        elif op == 0x05:                                                 # bne
            if a != b: nxt = (pc + 4 + (sext16(imm) << 2)) & MASK
        elif op == 0x02: nxt = ((pc + 4) & 0xF0000000) | ((ins & 0x3FFFFFF) << 2)   # j
        elif op == 0x03:                                                 # jal
            wreg(31, pc + 4)
            nxt = ((pc + 4) & 0xF0000000) | ((ins & 0x3FFFFFF) << 2)
        else:
            raise ValueError('unknown opcode %02x at pc %x' % (op, pc))

        if nxt == pc:                                    # "done: j done" -> stop
            return out
        pc = nxt
    raise RuntimeError('program did not finish in %d steps' % max_steps)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    print('\n'.join(run(sys.argv[1])))
