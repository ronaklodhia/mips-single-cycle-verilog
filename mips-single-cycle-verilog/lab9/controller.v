`timescale 1ns / 1ps
// ============================================================================
// lab9/controller.v -- control unit EXTENDED with ori and bne      [Lab 9]
// Changes vs. src/controller.v are marked  // NEW
// ============================================================================

// ----------------------------------------------------------------------------
// Main decoder, now 11 bits:
//   regwrite regdst alusrc branch bne memwrite memtoreg jump zeroext aluop[1:0]
// ----------------------------------------------------------------------------
module maindec (
    input  wire [5:0] op,
    output wire       regwrite,
    output wire       regdst,
    output wire       alusrc,
    output wire       branch,
    output wire       bne,       // NEW: 1 = this is bne
    output wire       memwrite,
    output wire       memtoreg,
    output wire       jump,
    output wire       zeroext,   // NEW: 1 = zero-extend the immediate (ori)
    output wire [1:0] aluop      // NEW code 11 = OR
);
    reg [10:0] controls;

    assign {regwrite, regdst, alusrc, branch, bne, memwrite,
            memtoreg, jump, zeroext, aluop} = controls;

    always @(*) begin
        case (op)               //   rw rd as br bn mw mr j  ze aluop
            6'b000000: controls = 11'b1__1__0__0__0__0__0__0__0__10; // R-type
            6'b100011: controls = 11'b1__0__1__0__0__0__1__0__0__00; // lw
            6'b101011: controls = 11'b0__0__1__0__0__1__0__0__0__00; // sw
            6'b000100: controls = 11'b0__0__0__1__0__0__0__0__0__01; // beq
            6'b001000: controls = 11'b1__0__1__0__0__0__0__0__0__00; // addi
            6'b000010: controls = 11'b0__0__0__0__0__0__0__1__0__00; // j
            6'b001101: controls = 11'b1__0__1__0__0__0__0__0__1__11; // ori  NEW
            6'b000101: controls = 11'b0__0__0__0__1__0__0__0__0__01; // bne  NEW
            default:   controls = 11'bxxxxxxxxxxx;
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// ALU decoder: one new aluop code.
// ----------------------------------------------------------------------------
module aludec (
    input  wire [5:0] funct,
    input  wire [1:0] aluop,
    output reg  [2:0] alucontrol
);
    always @(*) begin
        case (aluop)
            2'b00: alucontrol = 3'b010;                // add  (lw, sw, addi)
            2'b01: alucontrol = 3'b110;                // sub  (beq, bne)
            2'b11: alucontrol = 3'b001;                // or   (ori)  NEW
            default: begin
                case (funct)
                    6'b100000: alucontrol = 3'b010;    // add
                    6'b100010: alucontrol = 3'b110;    // sub
                    6'b100100: alucontrol = 3'b000;    // and
                    6'b100101: alucontrol = 3'b001;    // or
                    6'b101010: alucontrol = 3'b111;    // slt
                    default:   alucontrol = 3'bxxx;
                endcase
            end
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// Controller: bne is taken when the registers are NOT equal (zero = 0).
// ----------------------------------------------------------------------------
module controller (
    input  wire [5:0] op,
    input  wire [5:0] funct,
    input  wire       zero,
    output wire       memtoreg,
    output wire       memwrite,
    output wire       pcsrc,
    output wire       alusrc,
    output wire       regdst,
    output wire       regwrite,
    output wire       jump,
    output wire       zeroext,     // NEW: goes to the datapath's extender
    output wire [2:0] alucontrol
);
    wire [1:0] aluop;
    wire       branch, bne;

    maindec md (
        .op(op), .regwrite(regwrite), .regdst(regdst), .alusrc(alusrc),
        .branch(branch), .bne(bne), .memwrite(memwrite), .memtoreg(memtoreg),
        .jump(jump), .zeroext(zeroext), .aluop(aluop)
    );

    aludec ad (.funct(funct), .aluop(aluop), .alucontrol(alucontrol));

    assign pcsrc = (branch & zero) | (bne & ~zero);   // NEW: bne term
endmodule
