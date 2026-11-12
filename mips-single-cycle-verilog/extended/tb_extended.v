`timescale 1ns / 1ps
// ============================================================================
// extended/tb_extended.v -- testbench for the 19-instruction core
//
// Compile-time settings (run.sh passes them with -D):
//   PROGRAM  : hex file to run               e.g. "programs/test3.dat"
//   TRACE    : file that receives the trace  e.g. "build/test3.trace"
//   WAVES    : waveform file                 e.g. "build/test3.vcd"
//   EXPECTED : value the program must store to address 84
//
// Every register write and memory write is logged as one line ("R 8 12340000"
// or "M 84 0001670c"). tools/mipssim.py, a software model of the processor,
// prints the same lines; run.sh compares the two files (co-simulation).
// A program ends with a jump to itself ("done: j done").
// ============================================================================
`ifndef PROGRAM
`define PROGRAM "programs/test3.dat"
`endif
`ifndef TRACE
`define TRACE "build/test3.trace"
`endif
`ifndef WAVES
`define WAVES "build/test3.vcd"
`endif
`ifndef EXPECTED
`define EXPECTED 32'h0001670C
`endif

module tb_extended;
    reg         clk;
    reg         reset;
    wire [31:0] writedata, dataadr;
    wire        memwrite;
    integer     cycle, fd;
    reg         stored;            // 1 once the success store has been seen
    reg  [31:0] last_adr, last_data;

    top #(.MEMFILE(`PROGRAM)) dut (
        .clk(clk), .reset(reset),
        .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite)
    );

    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    initial begin
        $dumpfile(`WAVES);
        $dumpvars(0, tb_extended);
        fd = $fopen(`TRACE, "w");
        cycle = 0; stored = 1'b0; last_adr = 32'b0; last_data = 32'b0;
        reset = 1'b1;
        #22;
        reset = 1'b0;
        $display("=== Extended MIPS running %s ===", `PROGRAM);
    end

    always @(negedge clk) begin
        if (!reset) begin
            cycle = cycle + 1;
            if (dut.cpu.regwrite && dut.cpu.dp.writereg != 0)
                $fdisplay(fd, "R %0d %h", dut.cpu.dp.writereg, dut.cpu.dp.result);
            if (memwrite) begin
                $fdisplay(fd, "M %0d %h", dataadr, writedata);
                stored = 1'b1; last_adr = dataadr; last_data = writedata;
            end

            // "done: j done" -> the next PC equals the current PC: the program is over.
            if (dut.cpu.dp.pcnext === dut.pc) begin
                $fclose(fd);
                if (stored && last_adr === 32'd84 && last_data === `EXPECTED)
                    $display("Simulation succeeded: %0d instructions, final store mem[84] = 0x%h.",
                             cycle, last_data);
                else
                    $display("Simulation FAILED: final store was mem[%0d] = 0x%h, expected mem[84] = 0x%h.",
                             last_adr, last_data, `EXPECTED);
                $finish;
            end
        end
    end

    initial begin
        #50000;
        $display("Simulation FAILED: timeout, the program never reached its final jump.");
        $finish;
    end
endmodule
