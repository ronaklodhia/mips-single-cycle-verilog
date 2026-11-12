# fibonacci.asm -- writes the first 10 Fibonacci numbers to mem[0..36],
# reads them back and stores their sum. Exercises lw / sw through a pointer.
# If the processor is correct, the LAST store is mem[84] = 88 = 0x00000058.
#
main:   addi $s0, $0, 0          # p = 0 (address of the next slot)
        addi $t0, $0, 0          # a = F(0) = 0
        addi $t1, $0, 1          # b = F(1) = 1
        addi $s1, $0, 10         # count = 10
fill:   sw   $t0, 0($s0)         # mem[p] = a
        add  $t2, $t0, $t1       # c = a + b
        add  $t0, $t1, $0        # a = b
        add  $t1, $t2, $0        # b = c
        addi $s0, $s0, 4         # p = p + 4
        addi $s1, $s1, -1        # count = count - 1
        bne  $s1, $0, fill       # repeat 10 times
        addi $s0, $0, 0          # p = 0
        addi $s2, $0, 0          # sum = 0
sum:    slti $t3, $s0, 40        # p < 40 ?
        beq  $t3, $0, store      # no -> done adding
        lw   $t4, 0($s0)         # t4 = mem[p]
        add  $s2, $s2, $t4       # sum = sum + t4
        addi $s0, $s0, 4         # p = p + 4
        j    sum
store:  sw   $s2, 84($0)         # 0+1+1+2+3+5+8+13+21+34 = 88 -> success
done:   j    done                # stop here
