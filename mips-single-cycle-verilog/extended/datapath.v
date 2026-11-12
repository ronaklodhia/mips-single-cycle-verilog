`timescale 1ns / 1ps
// ============================================================================
// extended/datapath.v -- datapath for the 19-instruction core
// New hardware vs. lab9/datapath.v (marked  // NEW):
//   * immext3 : sign-extend, zero-extend, or place the immediate in the
//               upper half (lui)
//   * shifter : logical shift of rt by the shamt field (sll, srl)
//   * mux3    : 3-way multiplexers for the write register and the result
//   * one more PC source: register rs (jr)
// ============================================================================

// NEW: 3-to-1 multiplexer. s = 00 -> d0, 01 -> d1, 1x -> d2.
module mux3 #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire [WIDTH-1:0] d2,
    input  wire [1:0]       s,
    output wire [WIDTH-1:0] y
);
    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule

// NEW: immediate extender with three modes.
//   00 sign-extend   (addi, slti, lw, sw, beq, bne)   0x8000 -> 0xFFFF8000
//   01 zero-extend   (andi, ori)                      0x8000 -> 0x00008000
//   10 upper half    (lui)                            0x1234 -> 0x12340000
module immext3 (
    input  wire [15:0] a,
    input  wire [1:0]  immsrc,
    output reg  [31:0] y
);
    always @(*) begin
        case (immsrc)
            2'b00:   y = {{16{a[15]}}, a};
            2'b01:   y = {16'b0, a};
            default: y = {a, 16'b0};
        endcase
    end
endmodule

// NEW: logical shifter. Zeros are shifted in from the empty side.
module shifter (
    input  wire [31:0] a,          // register rt
    input  wire [4:0]  shamt,      // shift amount, instr[10:6]
    input  wire        right,      // 0 = left (sll), 1 = right (srl)
    output wire [31:0] y
);
    assign y = right ? (a >> shamt) : (a << shamt);
endmodule

module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire        pcsrc,
    input  wire        alusrc,
    input  wire [1:0]  regdst,     // NEW width
    input  wire        regwrite,
    input  wire        jump,
    input  wire        jr,         // NEW
    input  wire [1:0]  resultsrc,  // NEW (replaces memtoreg)
    input  wire [1:0]  immsrc,     // NEW (replaces zeroext)
    input  wire        shift,      // NEW
    input  wire        shiftright, // NEW
    input  wire [2:0]  alucontrol,
    output wire        zero,
    output wire [31:0] pc,
    input  wire [31:0] instr,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    input  wire [31:0] readdata
);
    wire [4:0]  writereg;
    wire [31:0] pcnext, pcnextbr, pcnextj, pcplus4, pcbranch, pcjump;
    wire [31:0] signimm, signimmsh;
    wire [31:0] srca, srcb;
    wire [31:0] shiftout, execout;                                  // NEW
    wire [31:0] result;

    // ---------------- next-PC logic ----------------
    flopr #(32) pcreg   (.clk(clk), .reset(reset), .d(pcnext), .q(pc));
    adder       pcadd1  (.a(pc), .b(32'd4), .y(pcplus4));
    sl2         immsh   (.a(signimm), .y(signimmsh));
    adder       pcadd2  (.a(pcplus4), .b(signimmsh), .y(pcbranch));
    mux2 #(32)  pcbrmux (.d0(pcplus4), .d1(pcbranch), .s(pcsrc), .y(pcnextbr));
    assign pcjump = {pcplus4[31:28], instr[25:0], 2'b00};
    mux2 #(32)  pcjmux  (.d0(pcnextbr), .d1(pcjump), .s(jump), .y(pcnextj));
    mux2 #(32)  pcjrmux (.d0(pcnextj), .d1(srca), .s(jr), .y(pcnext));      // NEW: jr -> PC = rs

    // ---------------- register file ----------------
    regfile     rf (
        .clk(clk), .we3(regwrite),
        .ra1(instr[25:21]), .ra2(instr[20:16]), .wa3(writereg),
        .wd3(result), .rd1(srca), .rd2(writedata)
    );
    mux3 #(5)   wrmux  (.d0(instr[20:16]), .d1(instr[15:11]), .d2(5'd31),   // NEW: $31 for jal
                        .s(regdst), .y(writereg));
    immext3     ext    (.a(instr[15:0]), .immsrc(immsrc), .y(signimm));     // NEW

    // ---------------- ALU and shifter ----------------
    mux2 #(32)  srcbmux (.d0(writedata), .d1(signimm), .s(alusrc), .y(srcb));
    alu         alu_unit (
        .a(srca), .b(srcb), .alucontrol(alucontrol),
        .result(aluout), .zero(zero)
    );
    shifter     sh      (.a(writedata), .shamt(instr[10:6]),                // NEW
                         .right(shiftright), .y(shiftout));
    mux2 #(32)  execmux (.d0(aluout), .d1(shiftout), .s(shift), .y(execout)); // NEW

    // ---------------- what gets written back ----------------
    mux3 #(32)  resmux  (.d0(execout), .d1(readdata), .d2(pcplus4),         // NEW: PC + 4 for jal
                         .s(resultsrc), .y(result));
endmodule
