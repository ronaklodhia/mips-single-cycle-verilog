`timescale 1ns / 1ps
// ============================================================================
// alu.v -- 32-bit MIPS ALU (Arithmetic Logic Unit)            [ETH DDCA Lab 5]
// ============================================================================
//
//   alucontrol | operation                      | used by
//   -----------+--------------------------------+---------------------------
//      000     | result = a AND b               | and
//      001     | result = a OR  b               | or (and ori in Lab 9)
//      010     | result = a + b                 | add, addi, lw, sw
//      110     | result = a - b                 | sub, beq (and bne in Lab 9)
//      111     | result = (a < b) ? 1 : 0       | slt  (signed compare)
//      100     | result = a AND (NOT b)         | (spare, from the lab sheet)
//      101     | result = a OR  (NOT b)         | (spare, from the lab sheet)
//
// The trick: alucontrol[2] = 1 means "use NOT b and add 1".
// In two's complement, a - b = a + (~b) + 1, so ONE adder does add AND sub.
// alucontrol[1:0] then picks which result goes out (AND, OR, sum, or SLT).
// ============================================================================

module alu (
    input  wire [31:0] a,           // operand A (always register rs)
    input  wire [31:0] b,           // operand B (register rt OR the immediate)
    input  wire [2:0]  alucontrol,  // which operation (from the ALU decoder)
    output reg  [31:0] result,      // the answer
    output wire        zero         // 1 when result == 0 (beq uses this)
);
    wire [31:0] b_mux;  // b, or ~b when subtracting
    wire [31:0] sum;    // output of the single 32-bit adder
    wire        slt;    // the "a is less than b" bit

    // Step 1: optionally invert b.
    assign b_mux = alucontrol[2] ? ~b : b;

    // Step 2: one adder. Carry-in = alucontrol[2] supplies the "+1" for subtract.
    assign sum = a + b_mux + alucontrol[2];

    // Step 3: signed less-than.
    //   If a and b have DIFFERENT signs, a < b exactly when a is negative.
    //   If they have the SAME sign, a - b cannot overflow, so the sign bit
    //   of (a - b) tells us the answer.
    assign slt = (a[31] != b[31]) ? a[31] : sum[31];

    // Step 4: pick the output with alucontrol[1:0].
    always @(*) begin
        case (alucontrol[1:0])
            2'b00:   result = a & b_mux;        // AND   (or AND-NOT)
            2'b01:   result = a | b_mux;        // OR    (or OR-NOT)
            2'b10:   result = sum;              // ADD   (or SUB)
            2'b11:   result = {31'b0, slt};     // SLT -> 0000...000 or 0000...001
            default: result = 32'b0;
        endcase
    end

    // Step 5: zero flag.
    assign zero = (result == 32'b0);
endmodule
