// Top-level module
module CPU (
    input clk,
    input reset,

    output wire [31:0] out_istr,

    output wire [6:0] o_funct7,
    output wire [2:0] o_funct3,
    output wire [4:0] o_opcode,
    output wire [31:0] o_imm
);

wire [7:0] intermediate_data;
// reg [7:0] output_data;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        // intermediate_data <= 8'b0;
        // output_data <= 8'b0;
    end else begin
        // Instantiate Module A
      
    end
end


ModuleA module_a (
    .clk(clk),
    .reset(reset),
    .data_in(8'b0),
    .data_out(intermediate_data)
);

// Instantiate Module B
// ModuleB module_b (
//     .clk(clk),
//     .reset(reset),
//     .data_in(8'b0),
//     .data_out(output_data)
// );


assign out_istr = 32'b0;

assign o_funct7 = 7'b0;
assign o_funct3 = 3'b0;
assign o_opcode = 5'b0;
assign o_imm = 32'b0;

endmodule

// Module A
module ModuleA (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    // parameter [7:0] processed_data = 8'b1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'b0;
        end else begin
            // Module A functionality
            // ...


            // data_out <= processed_data;
            // data_out <= 8'b1;
            data_out <= data_in + 8'b1;
        end
    end
endmodule

// Module B
module ModuleB (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'b0;
        end else begin
            // Module B functionality
            // ...
            data_out <= processed_data;
        end
    end
endmodule

