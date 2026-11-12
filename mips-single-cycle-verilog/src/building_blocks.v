`timescale 1ns / 1ps
// ============================================================================
// building_blocks.v -- small parts the datapath is built from      [Lab 8]
//   flopr   : flip-flop with reset (holds the PC)
//   mux2    : 2-to-1 multiplexer (a "switch" between two inputs)
//   adder   : 32-bit adder (PC + 4, branch target)
//   sl2     : shift left by 2 (word offset -> byte offset)
//   signext : sign extension 16 -> 32 bits
// ============================================================================

// ----------------------------------------------------------------------------
// flopr: a register of WIDTH flip-flops. On every rising clock edge it copies
// d into q. If reset is 1, q is forced to 0 at once (asynchronous reset).
// ----------------------------------------------------------------------------
module flopr #(parameter WIDTH = 8) (
    input  wire             clk,
    input  wire             reset,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset) q <= {WIDTH{1'b0}};  // WIDTH copies of 0
        else       q <= d;
    end
endmodule

// ----------------------------------------------------------------------------
// mux2: y = d0 when s = 0, y = d1 when s = 1.
// ----------------------------------------------------------------------------
module mux2 #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire             s,
    output wire [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

// ----------------------------------------------------------------------------
// adder: y = a + b (32 bits, carry-out ignored).
// ----------------------------------------------------------------------------
module adder (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);
    assign y = a + b;
endmodule

// ----------------------------------------------------------------------------
// sl2: shift left by 2 = multiply by 4. Drops the top 2 bits, appends 00.
// ----------------------------------------------------------------------------
module sl2 (
    input  wire [31:0] a,
    output wire [31:0] y
);
    assign y = {a[29:0], 2'b00};
endmodule

// ----------------------------------------------------------------------------
// signext: copy bit 15 (the sign bit) into the upper 16 bits.
//   0x0005 -> 0x00000005      0xFFF7 (-9) -> 0xFFFFFFF7 (-9)
// ----------------------------------------------------------------------------
module signext (
    input  wire [15:0] a,
    output wire [31:0] y
);
    assign y = {{16{a[15]}}, a};
endmodule
