`timescale 1ns / 1ps
// ============================================================================
// lab9/mips.v -- core EXTENDED with ori and bne                    [Lab 9]
// Only change vs. src/mips.v: one new wire, zeroext, from controller to datapath.
// ============================================================================

module mips (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc,
    input  wire [31:0] instr,
    output wire        memwrite,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    input  wire [31:0] readdata
);
    wire       memtoreg, alusrc, regdst, regwrite, jump, pcsrc, zero;
    wire       zeroext;                                         // NEW
    wire [2:0] alucontrol;

    controller c (
        .op(instr[31:26]), .funct(instr[5:0]), .zero(zero),
        .memtoreg(memtoreg), .memwrite(memwrite), .pcsrc(pcsrc),
        .alusrc(alusrc), .regdst(regdst), .regwrite(regwrite),
        .jump(jump), .zeroext(zeroext), .alucontrol(alucontrol)  // NEW port
    );

    datapath dp (
        .clk(clk), .reset(reset),
        .memtoreg(memtoreg), .pcsrc(pcsrc), .alusrc(alusrc),
        .regdst(regdst), .regwrite(regwrite), .jump(jump),
        .zeroext(zeroext),                                       // NEW port
        .alucontrol(alucontrol), .zero(zero),
        .pc(pc), .instr(instr),
        .aluout(aluout), .writedata(writedata), .readdata(readdata)
    );
endmodule
