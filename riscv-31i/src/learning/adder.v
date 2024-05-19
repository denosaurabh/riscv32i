
module HalfAdder(
    input wire a,
    input wire b,

    output wire sum,
    output wire carry
)

assign sum = a ^ b; //  XOR
assign carry = a & b; // AND

endmodule




module FullAdder(
    input wire a,
    input wire b,
    input wire c,

    output wire sum,
    output wire carry
)

assign {overflow, sum} = a + b + c;

endmodule


