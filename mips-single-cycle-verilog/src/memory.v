`timescale 1ns / 1ps
// ============================================================================
// memory.v -- instruction memory and data memory                   [Lab 8]
// Both are 64 words x 32 bits (256 bytes). MIPS addresses are BYTE addresses,
// and one word = 4 bytes, so word number = byte address / 4 = address[7:2].
// ============================================================================

// ----------------------------------------------------------------------------
// imem: instruction memory (read only). Loaded from a hex file at time 0.
// ----------------------------------------------------------------------------
module imem #(parameter MEMFILE = "programs/memfile.dat") (
    input  wire [5:0]  a,          // word address (pc[7:2])
    output wire [31:0] rd          // the instruction
);
    reg [31:0] RAM [0:63];

    initial $readmemh(MEMFILE, RAM);  // one 8-digit hex word per line

    assign rd = RAM[a];
endmodule

// ----------------------------------------------------------------------------
// dmem: data memory. Read is combinational, write happens on the clock edge.
// ----------------------------------------------------------------------------
module dmem (
    input  wire        clk,
    input  wire        we,         // write enable (memwrite, from sw)
    input  wire [31:0] a,          // byte address (the ALU result)
    input  wire [31:0] wd,         // data to write (register rt)
    output wire [31:0] rd          // data read (goes to register for lw)
);
    reg [31:0] RAM [0:63];

    assign rd = RAM[a[7:2]];

    always @(posedge clk) begin
        if (we) RAM[a[7:2]] <= wd;
    end
endmodule
