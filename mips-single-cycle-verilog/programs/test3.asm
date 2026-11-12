# test3.asm -- directed test for the 7 new instructions: andi slti lui sll srl jal jr
# If the processor is correct, the ONLY store is mem[84] = 0x0001670C.
#
#       assembly                 register values after it runs
main:   lui  $t0, 0x1234         # $t0 = 0x12340000 (immediate placed in the upper half)
        ori  $t0, $t0, 0x5678    # $t0 = 0x12345678
        andi $t1, $t0, 0x0FF0    # $t1 = 0x00000670 (zero-extended mask)
        sll  $t2, $t1, 4         # $t2 = 0x00006700
        srl  $t3, $t0, 28        # $t3 = 0x00000001
        slti $t4, $t3, 2         # $t4 = 1  (1 < 2)
        slti $t5, $t3, -1        # $t5 = 0  (1 < -1 is false: the immediate is sign-extended)
        addi $a0, $0, 6          # argument = 6
        jal  double              # $ra = address of the next line, jump to double
        add  $s0, $v0, $t2       # $s0 = 12 + 0x6700 = 0x670C
        add  $s0, $s0, $t4       # $s0 = 0x670D
        add  $s0, $s0, $t5       # unchanged
        lui  $t6, 0xFFFF         # $t6 = 0xFFFF0000
        andi $t7, $t6, 0xF00F    # $t7 = 0  (0xF00F is zero-extended, so the upper half is masked off)
        srl  $t6, $t6, 16        # $t6 = 0x0000FFFF (logical shift: zeros come in)
        add  $s0, $s0, $t6       # $s0 = 0x670D + 0xFFFF = 0x0001670C
        add  $s0, $s0, $t7       # unchanged
        sw   $s0, 84($0)         # mem[84] = 0x0001670C -> success
done:   j    done                # stop here
double: sll  $v0, $a0, 1         # $v0 = 2 * $a0
        jr   $ra                 # return
