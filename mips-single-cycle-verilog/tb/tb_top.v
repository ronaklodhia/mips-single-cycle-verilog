`timescale 1ns / 1ps
// ============================================================================
// tb_top.v -- testbench for the full single-cycle processor        [Lab 8]
// Runs programs/mipstest.asm. That program's last store is "sw $2, 84($0)"
// with $2 = 7. So: memory write of 7 to address 84  ==>  the CPU works.
// ============================================================================

module tb_top;
    reg         clk;
    reg         reset;
    wire [31:0] writedata, dataadr;
    wire        memwrite;
    integer     cycle;

    // The design under test, loaded with the Lab 8 test program.
    top #(.MEMFILE("programs/memfile.dat")) dut (
        .clk(clk), .reset(reset),
        .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite)
    );

    // 1) Clock: high 5 ns, low 5 ns -> 10 ns period (100 MHz).
    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    // 2) Start-up: open the waveform file, hold reset for 22 ns.
    initial begin
        $dumpfile("build/mips.vcd");
        $dumpvars(0, tb_top);
        cycle = 0;
        reset = 1'b1;
        #22;
        reset = 1'b0;
        $display("=== Lab 8: single-cycle MIPS running mipstest ===");
        $display("cyc  pc        instr     aluout    | what this instruction writes");
    end

    // 3) On every FALLING edge (signals are stable mid-cycle):
    //    print one trace line, then check stores.
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
                if (dataadr === 32'd84 && writedata === 32'd7) begin
                    $display("Simulation succeeded: wrote 7 to address 84.");
                    $finish;
                end else if (dataadr !== 32'd80) begin
                    $display("Simulation FAILED: unexpected store %h to address %0d.",
                             writedata, dataadr);
                    $finish;
                end
            end
        end
    end

    // 4) Safety net: stop after 1000 ns if the success store never comes.
    initial begin
        #1000;
        $display("Simulation FAILED: timeout, the final store never happened.");
        $finish;
    end
endmodule
