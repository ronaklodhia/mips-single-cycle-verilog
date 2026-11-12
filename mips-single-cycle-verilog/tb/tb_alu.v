`timescale 1ns / 1ps
// ============================================================================
// tb_alu.v -- self-checking testbench for the ALU              [Lab 5 + Lab 6]
// A "golden model" (plain Verilog operators) computes the expected answer;
// the testbench compares it with the ALU and counts mismatches.
// ============================================================================

module tb_alu;
    reg  [31:0] a, b;
    reg  [2:0]  alucontrol;
    wire [31:0] result;
    wire        zero;

    reg  [31:0] expected;
    integer     tests, errors, i, k;
    reg  [2:0]  ops [0:6];

    // Device Under Test (DUT)
    alu dut (.a(a), .b(b), .alucontrol(alucontrol), .result(result), .zero(zero));

    // Apply one input set, wait, compare with the golden model.
    task run_test;
        input [31:0] ta;
        input [31:0] tb;
        input [2:0]  tc;
        begin
            a = ta; b = tb; alucontrol = tc;
            #1;                                   // let the logic settle
            case (tc)
                3'b000: expected = a & b;
                3'b001: expected = a | b;
                3'b010: expected = a + b;
                3'b110: expected = a - b;
                3'b111: expected = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
                3'b100: expected = a & ~b;
                3'b101: expected = a | ~b;
                default: expected = 32'b0;
            endcase
            tests = tests + 1;
            if (result !== expected || zero !== (expected == 32'b0)) begin
                errors = errors + 1;
                $display("  MISMATCH op=%b a=%h b=%h -> got %h (zero=%b), expected %h",
                         tc, a, b, result, zero, expected);
            end
        end
    endtask

    initial begin
        tests = 0; errors = 0;
        $display("=== ALU test ===");

        // ---- directed tests: hand-picked edge cases ----
        run_test(32'h00000000, 32'h00000000, 3'b010);  // 0 + 0
        run_test(32'h00000000, 32'hFFFFFFFF, 3'b010);  // 0 + (-1)
        run_test(32'h00000001, 32'hFFFFFFFF, 3'b010);  // 1 + (-1) = 0 -> zero = 1
        run_test(32'h000000FF, 32'h00000001, 3'b010);  // carry across bytes
        run_test(32'h00000000, 32'h00000000, 3'b110);  // 0 - 0
        run_test(32'h00000000, 32'hFFFFFFFF, 3'b110);  // 0 - (-1) = 1
        run_test(32'h00000001, 32'h00000001, 3'b110);  // 1 - 1 = 0
        run_test(32'h00000100, 32'h00000001, 3'b110);  // borrow
        run_test(32'h00000000, 32'h00000000, 3'b111);  // 0 < 0 ? no
        run_test(32'h00000000, 32'h00000001, 3'b111);  // 0 < 1 ? yes
        run_test(32'h00000000, 32'hFFFFFFFF, 3'b111);  // 0 < -1 ? no
        run_test(32'hFFFFFFFF, 32'h00000000, 3'b111);  // -1 < 0 ? yes
        run_test(32'h7FFFFFFF, 32'h80000000, 3'b111);  // overflow case: no
        run_test(32'h80000000, 32'h7FFFFFFF, 3'b111);  // overflow case: yes
        run_test(32'hFFFFFFFF, 32'h12345678, 3'b000);  // AND
        run_test(32'h12345678, 32'h87654321, 3'b000);
        run_test(32'h12345678, 32'h87654321, 3'b001);  // OR
        run_test(32'h00000000, 32'h00000000, 3'b001);
        run_test(32'hF0F0F0F0, 32'hFF00FF00, 3'b100);  // AND-NOT
        run_test(32'h00000000, 32'hFFFFFFFF, 3'b101);  // OR-NOT

        // ---- random tests: 1000 per operation ----
        ops[0] = 3'b000; ops[1] = 3'b001; ops[2] = 3'b010; ops[3] = 3'b110;
        ops[4] = 3'b111; ops[5] = 3'b100; ops[6] = 3'b101;
        for (k = 0; k < 7; k = k + 1)
            for (i = 0; i < 1000; i = i + 1)
                run_test($random, $random, ops[k]);

        if (errors == 0)
            $display("ALU test passed: %0d / %0d checks correct.", tests, tests);
        else
            $display("ALU test FAILED: %0d of %0d checks wrong.", errors, tests);
        $finish;
    end
endmodule
