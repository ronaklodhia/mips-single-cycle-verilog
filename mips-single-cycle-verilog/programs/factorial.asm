# factorial.asm -- 6! = 720 on a processor with no multiplier.
# The function "mul" multiplies by shift-and-add; main calls it with jal / jr.
# If the processor is correct, the ONLY store is mem[84] = 720 = 0x000002D0.
#
main:   addi $s0, $0, 6          # n = 6
        addi $s1, $0, 1          # result = 1
loop:   beq  $s0, $0, finish     # while (n != 0) {
        add  $a0, $s1, $0        #     a0 = result
        add  $a1, $s0, $0        #     a1 = n
        jal  mul                 #     v0 = a0 * a1
        add  $s1, $v0, $0        #     result = v0
        addi $s0, $s0, -1        #     n = n - 1
        j    loop                # }
finish: sw   $s1, 84($0)         # mem[84] = 720 -> success
done:   j    done                # stop here

# mul: $v0 = $a0 * $a1. Looks at one bit of $a1 at a time.
mul:    add  $v0, $0, $0         # product = 0
mloop:  beq  $a1, $0, mdone      # while (a1 != 0) {
        andi $t0, $a1, 1         #     lowest bit of a1
        beq  $t0, $0, mskip      #     if it is 1:
        add  $v0, $v0, $a0       #         product += a0
mskip:  sll  $a0, $a0, 1         #     a0 = a0 * 2
        srl  $a1, $a1, 1         #     a1 = a1 / 2
        j    mloop               # }
mdone:  jr   $ra                 # return
