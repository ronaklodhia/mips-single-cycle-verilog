# test2.asm -- Lab 9 test program: checks the new ori and bne instructions
# If the processor is correct, the ONLY store is mem[84] = 0xFFFF7F02.
#
#       assembly               register values after it runs
main:   ori  $t0, $0,  0x8000  # $t0 = 0x00008000 (zero-extended, NOT 0xFFFF8000)
        addi $t1, $0,  -32768  # $t1 = 0xFFFF8000 (sign-extended)
        ori  $t2, $t0, 0x8001  # $t2 = 0x8000 OR 0x8001 = 0x00008001
        beq  $t0, $t1, there   # not equal -> not taken
        slt  $t3, $t1, $t0     # $t3 = (-32768 < 32768) = 1
        bne  $t3, $0,  here    # 1 != 0 -> taken
        j    there             # skipped
here:   sub  $t2, $t2, $t0     # $t2 = 0x8001 - 0x8000 = 1
        ori  $t0, $t0, 0xFF    # $t0 = 0x000080FF
there:  add  $t3, $t3, $t2     # $t3 = 1 + 1 = 2
        sub  $t0, $t2, $t0     # $t0 = 1 - 0x80FF = 0xFFFF7F02
        sw   $t0, 82($t3)      # mem[82 + 2 = 84] = 0xFFFF7F02 -> success
