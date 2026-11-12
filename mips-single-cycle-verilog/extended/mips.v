`timescale 1ns / 1ps
// ============================================================================
// extended/mips.v -- 19-instruction single-cycle core
//   Lab 8 : add sub and or slt lw sw beq addi j
//   Lab 9 : ori bne
//   here  : andi slti lui sll srl jal jr
// Same ports as src/mips.v, so src/top.v and the memories are reused as they are.
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
    wire       alusrc, regwrite, jump, jr, pcsrc, zero, shift, shiftright;
    wire [1:0] regdst, resultsrc, immsrc;
    wire [2:0] alucontrol;

    controller c (
        .op(instr[31:26]), .funct(instr[5:0]), .zero(zero),
        .memwrite(memwrite), .pcsrc(pcsrc), .alusrc(alusrc),
        .regdst(regdst), .regwrite(regwrite), .jump(jump), .jr(jr),
        .resultsrc(resultsrc), .immsrc(immsrc),
        .shift(shift), .shiftright(shiftright), .alucontrol(alucontrol)
    );

    datapath dp (
        .clk(clk), .reset(reset),
        .pcsrc(pcsrc), .alusrc(alusrc), .regdst(regdst),
        .regwrite(regwrite), .jump(jump), .jr(jr),
        .resultsrc(resultsrc), .immsrc(immsrc),
        .shift(shift), .shiftright(shiftright),
        .alucontrol(alucontrol), .zero(zero),
        .pc(pc), .instr(instr),
        .aluout(aluout), .writedata(writedata), .readdata(readdata)
    );
endmodule
