`timescale 1ns / 1ps
// ============================================================================
// mips.v -- the processor core = controller + datapath             [Lab 8]
// Supported instructions: add, sub, and, or, slt, lw, sw, beq, addi, j
// ============================================================================

module mips (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc,         // to instruction memory
    input  wire [31:0] instr,      // from instruction memory
    output wire        memwrite,   // to data memory
    output wire [31:0] aluout,     // to data memory (address)
    output wire [31:0] writedata,  // to data memory (data for sw)
    input  wire [31:0] readdata    // from data memory (data for lw)
);
    // wires that run between the controller and the datapath
    wire       memtoreg, alusrc, regdst, regwrite, jump, pcsrc, zero;
    wire [2:0] alucontrol;

    controller c (
        .op(instr[31:26]), .funct(instr[5:0]), .zero(zero),
        .memtoreg(memtoreg), .memwrite(memwrite), .pcsrc(pcsrc),
        .alusrc(alusrc), .regdst(regdst), .regwrite(regwrite),
        .jump(jump), .alucontrol(alucontrol)
    );

    datapath dp (
        .clk(clk), .reset(reset),
        .memtoreg(memtoreg), .pcsrc(pcsrc), .alusrc(alusrc),
        .regdst(regdst), .regwrite(regwrite), .jump(jump),
        .alucontrol(alucontrol), .zero(zero),
        .pc(pc), .instr(instr),
        .aluout(aluout), .writedata(writedata), .readdata(readdata)
    );
endmodule
