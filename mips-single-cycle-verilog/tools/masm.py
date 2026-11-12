#!/usr/bin/env python3
"""masm.py -- a tiny MIPS assembler for this project.

Turns a .asm file into a .dat file that $readmemh can load
(one 8-digit hex word per line, padded to 64 words).

Usage:   python3 tools/masm.py programs/mipstest.asm programs/memfile.dat

Supported: add sub and or slt sll srl jr | addi andi ori slti lui lw sw beq bne | j jal | nop
Labels ("name:"), comments ("#"), registers as $0..$31 or names ($t0, $s1 ...).
"""
import re
import sys

REG_NAMES = ['zero', 'at', 'v0', 'v1', 'a0', 'a1', 'a2', 'a3',
             't0', 't1', 't2', 't3', 't4', 't5', 't6', 't7',
             's0', 's1', 's2', 's3', 's4', 's5', 's6', 's7',
             't8', 't9', 'k0', 'k1', 'gp', 'sp', 'fp', 'ra']

R_TYPE = {'add': 0x20, 'sub': 0x22, 'and': 0x24, 'or': 0x25, 'slt': 0x2A}  # funct
SHIFT  = {'sll': 0x00, 'srl': 0x02}                                       # funct
I_ALU  = {'addi': 0x08, 'slti': 0x0A, 'andi': 0x0C, 'ori': 0x0D}          # opcode
MEM    = {'lw': 0x23, 'sw': 0x2B}
BRANCH = {'beq': 0x04, 'bne': 0x05}
JUMP   = {'j': 0x02, 'jal': 0x03}
MEM_WORDS = 64


def reg(tok):
    tok = tok.strip().lstrip('$')
    if tok.isdigit() and 0 <= int(tok) < 32:
        return int(tok)
    if tok in REG_NAMES:
        return REG_NAMES.index(tok)
    raise ValueError('bad register: $' + tok)


def imm(tok):
    return int(tok.strip(), 0)          # accepts 12, -9, 0x8000


def parse(path):
    """Return a list of (address, mnemonic, operands, source_line)."""
    prog, labels, addr = [], {}, 0
    for raw in open(path):
        line = raw.split('#')[0].strip()
        while ':' in line:                       # one or more labels
            name, line = line.split(':', 1)
            labels[name.strip()] = addr
            line = line.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        op = parts[0].lower()
        args = [a.strip() for a in parts[1].split(',')] if len(parts) > 1 else []
        prog.append((addr, op, args, raw.rstrip()))
        addr += 4
    return prog, labels


def encode(addr, op, args, labels):
    if op in R_TYPE:                             # op rd, rs, rt
        rd, rs, rt = reg(args[0]), reg(args[1]), reg(args[2])
        return (rs << 21) | (rt << 16) | (rd << 11) | R_TYPE[op]
    if op in SHIFT:                              # op rd, rt, shamt
        rd, rt, sh = reg(args[0]), reg(args[1]), imm(args[2])
        return (rt << 16) | (rd << 11) | ((sh & 0x1F) << 6) | SHIFT[op]
    if op == 'jr':                               # jr rs
        return (reg(args[0]) << 21) | 0x08
    if op == 'nop':                              # nop = sll $0, $0, 0
        return 0
    if op == 'lui':                              # lui rt, imm
        return (0x0F << 26) | (reg(args[0]) << 16) | (imm(args[1]) & 0xFFFF)
    if op in I_ALU:                              # op rt, rs, imm
        rt, rs, k = reg(args[0]), reg(args[1]), imm(args[2])
        return (I_ALU[op] << 26) | (rs << 21) | (rt << 16) | (k & 0xFFFF)
    if op in MEM:                                # op rt, offset(rs)
        rt = reg(args[0])
        m = re.match(r'(-?\w+)\((\$\w+)\)', args[1].replace(' ', ''))
        k, rs = imm(m.group(1)), reg(m.group(2))
        return (MEM[op] << 26) | (rs << 21) | (rt << 16) | (k & 0xFFFF)
    if op in BRANCH:                             # op rs, rt, label
        rs, rt = reg(args[0]), reg(args[1])
        offset = (labels[args[2]] - (addr + 4)) // 4   # counted in words from PC+4
        return (BRANCH[op] << 26) | (rs << 21) | (rt << 16) | (offset & 0xFFFF)
    if op in JUMP:                               # j label / jal label
        return (JUMP[op] << 26) | ((labels[args[0]] >> 2) & 0x3FFFFFF)
    raise ValueError('unsupported instruction: ' + op)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    prog, labels = parse(sys.argv[1])
    words = []
    print('addr  machine   source')
    for addr, op, args, src in prog:
        w = encode(addr, op, args, labels)
        words.append(w)
        print('%04x  %08x  %s' % (addr, w, src.split('#')[0].strip()))
    if len(words) > MEM_WORDS:
        sys.exit('program too long for a %d-word memory' % MEM_WORDS)
    words += [0] * (MEM_WORDS - len(words))
    with open(sys.argv[2], 'w') as f:
        f.write('\n'.join('%08x' % w for w in words) + '\n')
    print('wrote %d instructions (+ padding) to %s' % (len(prog), sys.argv[2]))


if __name__ == '__main__':
    main()
