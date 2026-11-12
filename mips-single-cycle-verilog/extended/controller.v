`timescale 1ns / 1ps
// ============================================================================
// extended/controller.v -- control unit for the 19-instruction core
// Adds andi, slti, lui, sll, srl, jal, jr to the Lab 9 controller.
// Changes vs. lab9/controller.v are marked  // NEW
// ============================================================================

// ----------------------------------------------------------------------------
// Main decoder, now 15 bits:
//   regwrite regdst[1:0] alusrc branch bne memwrite resultsrc[1:0] jump
//   immsrc[1:0] aluop[2:0]
//
//   regdst    : 00 = rt, 01 = rd, 10 = $31 (jal)                       NEW width
//   resultsrc : 00 = ALU or shifter, 01 = memory, 10 = PC + 4 (jal)    NEW
//   immsrc    : 00 = sign-extend, 01 = zero-extend, 10 = upper (lui)   NEW
//   aluop     : 000 add, 001 sub, 010 look at funct,
//               011 or, 100 and, 101 slt                               NEW width
// ----------------------------------------------------------------------------
module maindec (
    input  wire [5:0] op,
    output wire       regwrite,
    output wire [1:0] regdst,
    output wire       alusrc,
    output wire       branch,
    output wire       bne,
    output wire       memwrite,
    output wire [1:0] resultsrc,
    output wire       jump,
    output wire [1:0] immsrc,
    output wire [2:0] aluop
);
    reg [14:0] controls;

    assign {regwrite, regdst, alusrc, branch, bne, memwrite,
            resultsrc, jump, immsrc, aluop} = controls;

    always @(*) begin
        case (op)               //   rw rd  as br bn mw rs  j  im  aluop
            6'b000000: controls = 15'b1__01__0__0__0__0__00__0__00__010; // R-type
            6'b100011: controls = 15'b1__00__1__0__0__0__01__0__00__000; // lw
            6'b101011: controls = 15'b0__00__1__0__0__1__00__0__00__000; // sw
            6'b000100: controls = 15'b0__00__0__1__0__0__00__0__00__001; // beq
            6'b000101: controls = 15'b0__00__0__0__1__0__00__0__00__001; // bne
            6'b001000: controls = 15'b1__00__1__0__0__0__00__0__00__000; // addi
            6'b001101: controls = 15'b1__00__1__0__0__0__00__0__01__011; // ori
            6'b000010: controls = 15'b0__00__0__0__0__0__00__1__00__000; // j
            6'b001010: controls = 15'b1__00__1__0__0__0__00__0__00__101; // slti NEW
            6'b001100: controls = 15'b1__00__1__0__0__0__00__0__01__100; // andi NEW
            6'b001111: controls = 15'b1__00__1__0__0__0__00__0__10__011; // lui  NEW (0 OR imm<<16)
            6'b000011: controls = 15'b1__10__0__0__0__0__10__1__00__000; // jal  NEW
            default:   controls = 15'bxxxxxxxxxxxxxxx;
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// ALU decoder. For R-type it now also spots the three instructions that do
// not use the ALU: sll, srl (shifter) and jr (jump to a register).     NEW
// ----------------------------------------------------------------------------
module aludec (
    input  wire [5:0] funct,
    input  wire [2:0] aluop,
    output reg  [2:0] alucontrol,
    output reg        shift,       // NEW: 1 = result comes from the shifter
    output reg        shiftright,  // NEW: 0 = sll, 1 = srl
    output reg        jr           // NEW: 1 = this is jr
);
    always @(*) begin
        shift = 1'b0; shiftright = 1'b0; jr = 1'b0;
        case (aluop)
            3'b000: alucontrol = 3'b010;               // add  (lw, sw, addi, j, jal)
            3'b001: alucontrol = 3'b110;               // sub  (beq, bne)
            3'b011: alucontrol = 3'b001;               // or   (ori, lui)
            3'b100: alucontrol = 3'b000;               // and  (andi)        NEW
            3'b101: alucontrol = 3'b111;               // slt  (slti)        NEW
            default: begin                             // 010: R-type
                case (funct)
                    6'b100000: alucontrol = 3'b010;    // add
                    6'b100010: alucontrol = 3'b110;    // sub
                    6'b100100: alucontrol = 3'b000;    // and
                    6'b100101: alucontrol = 3'b001;    // or
                    6'b101010: alucontrol = 3'b111;    // slt
                    6'b000000: begin alucontrol = 3'b010; shift = 1'b1; end                     // sll NEW
                    6'b000010: begin alucontrol = 3'b010; shift = 1'b1; shiftright = 1'b1; end  // srl NEW
                    6'b001000: begin alucontrol = 3'b010; jr = 1'b1; end                        // jr  NEW
                    default:   alucontrol = 3'bxxx;
                endcase
            end
        endcase
    end
endmodule

// ----------------------------------------------------------------------------
// Controller. jr is an R-type, so the main decoder asks for a register write;
// the gate below cancels it.                                            NEW
// ----------------------------------------------------------------------------
module controller (
    input  wire [5:0] op,
    input  wire [5:0] funct,
    input  wire       zero,
    output wire       memwrite,
    output wire       pcsrc,
    output wire       alusrc,
    output wire [1:0] regdst,
    output wire       regwrite,
    output wire       jump,
    output wire       jr,          // NEW
    output wire [1:0] resultsrc,   // NEW
    output wire [1:0] immsrc,      // NEW
    output wire       shift,       // NEW
    output wire       shiftright,  // NEW
    output wire [2:0] alucontrol
);
    wire [2:0] aluop;
    wire       branch, bne, regwrite_md, jr_dec;

    maindec md (
        .op(op), .regwrite(regwrite_md), .regdst(regdst), .alusrc(alusrc),
        .branch(branch), .bne(bne), .memwrite(memwrite), .resultsrc(resultsrc),
        .jump(jump), .immsrc(immsrc), .aluop(aluop)
    );

    aludec ad (
        .funct(funct), .aluop(aluop), .alucontrol(alucontrol),
        .shift(shift), .shiftright(shiftright), .jr(jr_dec)
    );

    assign jr       = jr_dec;
    assign regwrite = regwrite_md & ~jr_dec;                  // NEW: jr writes nothing
    assign pcsrc    = (branch & zero) | (bne & ~zero);
endmodule
