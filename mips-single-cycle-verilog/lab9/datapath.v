`timescale 1ns / 1ps
// ============================================================================
// lab9/datapath.v -- datapath EXTENDED for ori                     [Lab 9]
// Only change vs. src/datapath.v: the sign extender becomes an extender that
// can also zero-extend, chosen by the new zeroext control signal.  // NEW
// ============================================================================

// NEW: zeroext = 1 -> fill the top 16 bits with 0 (ori: 0x8000 -> 0x00008000)
//      zeroext = 0 -> fill with the sign bit     (addi: 0x8000 -> 0xFFFF8000)
module immext (
    input  wire [15:0] a,
    input  wire        zeroext,
    output wire [31:0] y
);
    assign y = zeroext ? {16'b0, a} : {{16{a[15]}}, a};
endmodule

module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire        memtoreg,
    input  wire        pcsrc,
    input  wire        alusrc,
    input  wire        regdst,
    input  wire        regwrite,
    input  wire        jump,
    input  wire        zeroext,    // NEW
    input  wire [2:0]  alucontrol,
    output wire        zero,
    output wire [31:0] pc,
    input  wire [31:0] instr,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    input  wire [31:0] readdata
);
    wire [4:0]  writereg;
    wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch, pcjump;
    wire [31:0] signimm, signimmsh;
    wire [31:0] srca, srcb;
    wire [31:0] result;

    // next-PC logic (unchanged)
    flopr #(32) pcreg   (.clk(clk), .reset(reset), .d(pcnext), .q(pc));
    adder       pcadd1  (.a(pc), .b(32'd4), .y(pcplus4));
    sl2         immsh   (.a(signimm), .y(signimmsh));
    adder       pcadd2  (.a(pcplus4), .b(signimmsh), .y(pcbranch));
    mux2 #(32)  pcbrmux (.d0(pcplus4), .d1(pcbranch), .s(pcsrc), .y(pcnextbr));
    assign pcjump = {pcplus4[31:28], instr[25:0], 2'b00};
    mux2 #(32)  pcmux   (.d0(pcnextbr), .d1(pcjump), .s(jump), .y(pcnext));

    // register file (unchanged)
    regfile     rf (
        .clk(clk), .we3(regwrite),
        .ra1(instr[25:21]), .ra2(instr[20:16]), .wa3(writereg),
        .wd3(result), .rd1(srca), .rd2(writedata)
    );
    mux2 #(5)   wrmux  (.d0(instr[20:16]), .d1(instr[15:11]), .s(regdst), .y(writereg));
    mux2 #(32)  resmux (.d0(aluout), .d1(readdata), .s(memtoreg), .y(result));
    immext      ext    (.a(instr[15:0]), .zeroext(zeroext), .y(signimm));   // NEW

    // ALU (unchanged)
    mux2 #(32)  srcbmux (.d0(writedata), .d1(signimm), .s(alusrc), .y(srcb));
    alu         alu_unit (
        .a(srca), .b(srcb), .alucontrol(alucontrol),
        .result(aluout), .zero(zero)
    );
endmodule
