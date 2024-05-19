/*
 * Copyright (c) 2024 denosaurabh
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire       clk,      // clock

    input  wire       rst_n,     // reset_n - low to reset
    input  wire [7:0] ui_in,    // Dedicated inputs
    input  wire [7:0] uio_in,   // IOs: Input path
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it

    output wire [7:0] uo_out,   // Dedicated outputs
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe   // IOs: Enable path (active high: 0=input, 1=output)
);

// All output pins must be assigned. If not used, assign to 0.
assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
assign uio_out = 0;
assign uio_oe  = 0;

endmodule
