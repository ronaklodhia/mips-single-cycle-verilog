`timescale 1ns / 1ps
// ============================================================================
// datapath.v -- every block the data flows through                 [Lab 8]
// Three groups: (1) next-PC logic  (2) register file  (3) ALU
// The control unit drives the select lines; the datapath only obeys them.
// ============================================================================

module datapath (
    input  wire        clk,
    input  wire        reset,
    // control signals (from the controller)
    input  wire        memtoreg,
    input  wire        pcsrc,
    input  wire        alusrc,
    input  wire        regdst,
    input  wire        regwrite,
    input  wire        jump,
    input  wire [2:0]  alucontrol,
    // status back to the controller
    output wire        zero,
    // instruction memory side
    output wire [31:0] pc,
    input  wire [31:0] instr,
    // data memory side
    output wire [31:0] aluout,     // also the data-memory address
    output wire [31:0] writedata,  // register rt, stored by sw
    input  wire [31:0] readdata    // loaded by lw
);
    wire [4:0]  writereg;          // which register to write
    wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch, pcjump;
    wire [31:0] signimm, signimmsh;
    wire [31:0] srca, srcb;
    wire [31:0] result;            // value written to the register file

    // ---------------- (1) next-PC logic ----------------
    flopr #(32) pcreg   (.clk(clk), .reset(reset), .d(pcnext), .q(pc));
    adder       pcadd1  (.a(pc), .b(32'd4), .y(pcplus4));            // PC + 4
    sl2         immsh   (.a(signimm), .y(signimmsh));               // offset * 4
    adder       pcadd2  (.a(pcplus4), .b(signimmsh), .y(pcbranch)); // branch target
    mux2 #(32)  pcbrmux (.d0(pcplus4), .d1(pcbranch), .s(pcsrc), .y(pcnextbr));
    assign pcjump = {pcplus4[31:28], instr[25:0], 2'b00};          // jump target
    mux2 #(32)  pcmux   (.d0(pcnextbr), .d1(pcjump), .s(jump), .y(pcnext));

    // ---------------- (2) register file ----------------
    regfile     rf (
        .clk(clk), .we3(regwrite),
        .ra1(instr[25:21]), .ra2(instr[20:16]), .wa3(writereg),
        .wd3(result), .rd1(srca), .rd2(writedata)
    );
    mux2 #(5)   wrmux  (.d0(instr[20:16]), .d1(instr[15:11]), .s(regdst), .y(writereg));
    mux2 #(32)  resmux (.d0(aluout), .d1(readdata), .s(memtoreg), .y(result));
    signext     se     (.a(instr[15:0]), .y(signimm));

    // ---------------- (3) ALU ----------------
    mux2 #(32)  srcbmux (.d0(writedata), .d1(signimm), .s(alusrc), .y(srcb));
    alu         alu_unit (
        .a(srca), .b(srcb), .alucontrol(alucontrol),
        .result(aluout), .zero(zero)
    );
endmodule
