module MultiBitMultiplexer(
    input wire [31:0] a,
    input wire [31:0] a,
    input wire sel,
    output wire [31:0] out
)

assign out = sel ? a : b;

endmodule



module MultiwayMultiBitMultiplexer(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,

    input wire [1:0] se,

    output reg [31:0] out
)
    case (se)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
        2'b11: out = d;
        default: out = 32'b0;
    endcase

endmodule


