module InstructionMemory (
    input wire [31:0] address,
    output reg [31:0] instruction
);

// Example memory initialization (256 x 32-bit memory)
reg [31:0] RAM [0:255];

// Initialize the memory with instructions (for simulation purposes)
initial begin
    $readmemb("instructions.bin", RAM);
end

always @(*) begin
    instruction = RAM[address >> 2]; // Fetch instruction (word-aligned address)
end

endmodule