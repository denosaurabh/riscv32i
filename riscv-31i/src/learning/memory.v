module FlipFlop(
    input wire clk,
    input wire rst,
    input wire d,

    output reg q
)

always @(posedge clk or posedge rst) begin

    if (rst) begin
        q <= 1'b0;
    end else begin
        q <= d;
    end

end

endmodule;




module Register(
    input wire clk,
    input wire rst,
    
    input wire in,
    input wire load,

    output reg out,
)

always @(posedge clk or posedge rst) begin

    if (rst) begin
        out <= 32'b0;
    end else if (load) begin
        out <= in;
    end else if (~load) begin
        out <= out;
    end


endmodule;





module Memory(

)

reg [7:0] BYTE_RAM; 
reg [7:0] BYTE_RAM[0:7]; // 8x8 = 64_RAM
reg [63:0] BYTE_RAM[0:7]; // (8x8)x8 = 512_RAM



endmodule