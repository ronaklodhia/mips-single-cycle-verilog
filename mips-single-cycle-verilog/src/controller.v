`timescale 1ns / 1ps
// ============================================================================
// controller.v -- the control unit                                 [Lab 8]
//   maindec    : opcode (instr[31:26]) -> 8 control signals + 2-bit aluop
//   aludec     : aluop + funct (instr[5:0]) -> 3-bit alucontrol
//   controller : the two decoders + the branch AND gate
// ============================================================================

// ----------------------------------------------------------------------------
// Main decoder. One row per instruction type. The 9 bits are, in order:
//   regwrite regdst alusrc branch memwrite memtoreg jump aluop[1:0]
// ----------------------------------------------------------------------------
module maindec (
    input  wire [5:0] op,
    output wire       regwrite,  // 1 = write a result into the register file
    output wire       regdst,    // 1 = destination is rd (R-type), 0 = rt
    output wire       alusrc,    // 1 = ALU input B is the immediate, 0 = rt
    output wire       branch,    // 1 = this is beq
    output wire       memwrite,  // 1 = write data memory (sw)
    output wire       memtoreg,  // 1 = register gets memory data (lw)
    output wire       jump,      // 1 = this is j
    output wire [1:0] aluop      // 00 = add, 01 = subtract, 10 = look at funct
);
    reg [8:0] controls;

    // Split the 9-bit vector into the named outputs (concatenation on the left).
    assign {regwrite, regdst, alusrc, branch, memwrite,
            memtoreg, jump, aluop} = controls;

    always @(*) begin
        case (op)               //  rw rd as br mw mr j  aluop
            6'b000000: controls = 9'b1__1__0__0__0__0__0__10;  // R-type
            6'b100011: controls = 9'b1__0__1__0__0__1__0__00;  // lw
            6'b101011: controls = 9'b0__0__1__0__1__0__0__00;  // sw
            6'b000100: controls = 9'b0__0__0__1__0__0__0__01;  // beq
            6'b001000: controls = 9'b1__0__1__0__0__0__0__00;  // addi
            6'b000010: controls = 9'b0__0__0__0__0__0__1__00;  // j
            default:   controls = 9'bxxxxxxxxx;                // unknown
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// ALU decoder. aluop says what the main decoder already knows; for R-type
// (aluop = 10) the funct field picks the operation.
// ----------------------------------------------------------------------------
module aludec (
    input  wire [5:0] funct,
    input  wire [1:0] aluop,
    output reg  [2:0] alucontrol
);
    always @(*) begin
        case (aluop)
            2'b00: alucontrol = 3'b010;                // add  (lw, sw, addi)
            2'b01: alucontrol = 3'b110;                // sub  (beq)
            default: begin
                case (funct)                           // R-type
                    6'b100000: alucontrol = 3'b010;    // add
                    6'b100010: alucontrol = 3'b110;    // sub
                    6'b100100: alucontrol = 3'b000;    // and
                    6'b100101: alucontrol = 3'b001;    // or
                    6'b101010: alucontrol = 3'b111;    // slt
                    default:   alucontrol = 3'bxxx;    // unknown
                endcase
            end
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// Controller = main decoder + ALU decoder + "take the branch?" gate.
// ----------------------------------------------------------------------------
module controller (
    input  wire [5:0] op,
    input  wire [5:0] funct,
    input  wire       zero,        // from the ALU: 1 when rs - rt == 0
    output wire       memtoreg,
    output wire       memwrite,
    output wire       pcsrc,       // 1 = next PC is the branch target
    output wire       alusrc,
    output wire       regdst,
    output wire       regwrite,
    output wire       jump,
    output wire [2:0] alucontrol
);
    wire [1:0] aluop;
    wire       branch;

    maindec md (
        .op(op), .regwrite(regwrite), .regdst(regdst), .alusrc(alusrc),
        .branch(branch), .memwrite(memwrite), .memtoreg(memtoreg),
        .jump(jump), .aluop(aluop)
    );

    aludec ad (.funct(funct), .aluop(aluop), .alucontrol(alucontrol));

    // beq is taken only if it IS a branch AND the two registers are equal.
    assign pcsrc = branch & zero;
endmodule
