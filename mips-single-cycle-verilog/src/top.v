`timescale 1ns / 1ps
// ============================================================================
// top.v -- the whole computer: MIPS core + instruction memory + data memory
// ============================================================================

module top #(parameter MEMFILE = "programs/memfile.dat") (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] writedata,  // brought out so the testbench can watch stores
    output wire [31:0] dataadr,
    output wire        memwrite
);
    wire [31:0] pc, instr, readdata;

    mips cpu (
        .clk(clk), .reset(reset),
        .pc(pc), .instr(instr),
        .memwrite(memwrite), .aluout(dataadr),
        .writedata(writedata), .readdata(readdata)
    );

    imem #(.MEMFILE(MEMFILE)) im (.a(pc[7:2]), .rd(instr));

    dmem dm (
        .clk(clk), .we(memwrite),
        .a(dataadr), .wd(writedata), .rd(readdata)
    );
endmodule
