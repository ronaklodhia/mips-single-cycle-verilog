# mipstest.asm -- Lab 8 test program (Harris & Harris, Figure 7.60)
# Uses every supported instruction: add sub and or slt addi lw sw beq j
# If the processor is correct, the LAST store is mem[84] = 7.
#
#       assembly              meaning                    address  machine code
main:   addi $2, $0, 5        # $2 = 5                     0x00    20020005
        addi $3, $0, 12       # $3 = 12                    0x04    2003000c
        addi $7, $3, -9       # $7 = 12 - 9 = 3            0x08    2067fff7
        or   $4, $7, $2       # $4 = 3 OR 5 = 7            0x0c    00e22025
        and  $5, $3, $4       # $5 = 12 AND 7 = 4          0x10    00642824
        add  $5, $5, $4       # $5 = 4 + 7 = 11            0x14    00a42820
        beq  $5, $7, end      # 11 == 3? no, not taken     0x18    10a7000a
        slt  $4, $3, $4       # $4 = (12 < 7) = 0          0x1c    0064202a
        beq  $4, $0, around   # 0 == 0? yes, taken         0x20    10800001
        addi $5, $0, 0        # skipped                    0x24    20050000
around: slt  $4, $7, $2       # $4 = (3 < 5) = 1           0x28    00e2202a
        add  $7, $4, $5       # $7 = 1 + 11 = 12           0x2c    00853820
        sub  $7, $7, $2       # $7 = 12 - 5 = 7            0x30    00e23822
        sw   $7, 68($3)       # mem[12 + 68 = 80] = 7      0x34    ac670044
        lw   $2, 80($0)       # $2 = mem[80] = 7           0x38    8c020050
        j    end              # jump to end                0x3c    08000011
        addi $2, $0, 1        # skipped                    0x40    20020001
end:    sw   $2, 84($0)       # mem[84] = 7  -> success    0x44    ac020054
