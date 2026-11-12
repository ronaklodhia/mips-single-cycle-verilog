`timescale 1ns / 1ps
// ============================================================================
// regfile.v -- 32 x 32-bit register file                           [Lab 8]
// ============================================================================
//   * Two READ ports (ra1 -> rd1, ra2 -> rd2): combinational, no clock.
//   * One WRITE port (wa3, wd3, we3): writes on the rising clock edge.
//   * Register $0 always reads as 0 (MIPS rule), whatever was written to it.
// ============================================================================

module regfile (
    input  wire        clk,
    input  wire        we3,        // write enable
    input  wire [4:0]  ra1,        // read address 1  (instr[25:21] = rs)
    input  wire [4:0]  ra2,        // read address 2  (instr[20:16] = rt)
    input  wire [4:0]  wa3,        // write address   (rt or rd)
    input  wire [31:0] wd3,        // write data      (ALU result or memory data)
    output wire [31:0] rd1,        // read data 1
    output wire [31:0] rd2         // read data 2
);
    reg [31:0] rf [0:31];          // 32 registers, each 32 bits wide

    // Write: only on a rising clock edge, only if we3 = 1.
    always @(posedge clk) begin
        if (we3) rf[wa3] <= wd3;
    end

    // Read: any time the address changes. Address 0 returns 0.
    assign rd1 = (ra1 != 5'd0) ? rf[ra1] : 32'b0;
    assign rd2 = (ra2 != 5'd0) ? rf[ra2] : 32'b0;
endmodule
