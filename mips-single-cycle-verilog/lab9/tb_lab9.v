`timescale 1ns / 1ps
// ============================================================================
// lab9/tb_lab9.v -- testbench for the extended processor           [Lab 9]
// Runs programs/test2.asm. Its ONLY store must be 0xFFFF7F02 to address 84.
// ============================================================================

module tb_lab9;
    reg         clk;
    reg         reset;
    wire [31:0] writedata, dataadr;
    wire        memwrite;
    integer     cycle;

    top #(.MEMFILE("programs/test2.dat")) dut (
        .clk(clk), .reset(reset),
        .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite)
    );

    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    initial begin
        $dumpfile("build/lab9.vcd");
        $dumpvars(0, tb_lab9);
        cycle = 0;
        reset = 1'b1;
        #22;
        reset = 1'b0;
        $display("=== Lab 9: extended MIPS (ori, bne) running test2 ===");
        $display("cyc  pc        instr     aluout    | what this instruction writes");
    end

    always @(negedge clk) begin
        if (!reset) begin
            $write("%3d  %h  %h  %h  | ", cycle, dut.pc, dut.instr, dataadr);
            if (dut.cpu.regwrite && dut.cpu.dp.writereg != 0)
                $display("$%0d <= %h", dut.cpu.dp.writereg, dut.cpu.dp.result);
            else if (memwrite)
                $display("mem[%0d] <= %h", dataadr, writedata);
            else
                $display("(no write: branch or jump)");
            cycle = cycle + 1;

            if (memwrite) begin
                if (dataadr === 32'd84 && writedata === 32'hFFFF7F02)
                    $display("Simulation succeeded: wrote 0xFFFF7F02 to address 84.");
                else
                    $display("Simulation FAILED: store %h to address %0d.",
                             writedata, dataadr);
                $finish;
            end
        end
    end

    initial begin
        #1000;
        $display("Simulation FAILED: timeout, the store never happened.");
        $finish;
    end
endmodule
