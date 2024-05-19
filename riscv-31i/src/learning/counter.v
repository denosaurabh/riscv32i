module ProgramCounter(
    input wire clk,
    input wire enable,
    input wire reset,

    output reg [7:0] counter
)

always @(posedge clk or posedge reset) begin

    if (reset) begin
        counter <= 0;
    end else if (enable) begin
        counter <= counter + 1;
    end


end


endmodule;


