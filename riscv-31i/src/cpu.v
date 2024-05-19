// https://www.fromthetransistor.com

module CPU(
    input clk,
    input reset,

    output [31:0] out_istr
)

ProgramCounter programCounter (
    .clk(clk),
    .rst(reset),
    .enable(1'b1),

    .load(0'b1),
    .addr(31b'0),

    .pc(pc)
)


InstructionMemory InstructionMemory (
    .addr(pc),
    .istr_out(intr_adr)
)


assign out_istr = intr_adr;

endmodule;





module ProgramCounter(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire load,
    input wire [31:0] addr,
    
    output reg [31:0] pc
);

always @(posedge clk or negedge rst) begin
    
    if (rst) begin
        pc <= 32'b0;
    end else if (enable) begin
        if (load) begin
            pc <= addr;
        end else begin
            pc <= pc + 32'b1;
        end
    end

end

endmodule





module InstructionMemory(
    input wire [31:0] addr,
    output reg [31:0] istr_out
)

reg [31:0] RAM[0:255]; // RAM with 32-bits x 256

always @(addr) begin
    // Fetch instruction based on address. Address is divided by 4 (shifted right by 2 bits) 
    // because each instruction is 4 bytes (32 bits) wide.
    istr_out <= RAM[addr >> 2];
end


initial begin
    // Initialize memory with some instructions. This is just a placeholder.
    // In a real scenario, the program or compiler output would populate this.
    memory[0] = 32'b00100100100100100100100100100100;  // Just example data
    memory[1] = 32'b00100100100100100100100100100101;  
    // ... more instructions ...
end



endmodule







module RV32I_Decoder (
    input [31:0] instr,  // 32-bit instruction input
    output reg [6:0] funct7, // funct7 field
    output reg [2:0] funct3, // funct3 field
    output reg [4:0] opcode, // opcode field
    output reg [31:0] imm,   // immediate value, sign-extended when necessary
    output reg R_type,  // Signal indicating R-type instruction
    output reg I_type,  // Signal indicating I-type instruction
    output reg S_type,   // Signal indicating S-type instruction
    output reg B_type,
    output reg U_type,
    output reg J_type
);

parameter OPCODE_R = 7'b0110011; // R-type
parameter OPCODE_I = 7'b0010011; // I-type (immediate operations)
parameter OPCODE_LOAD = 7'b0000011; // Load instructions (I-type format)
parameter OPCODE_STORE = 7'b0100011; // Store instructions (S-type format)
parameter OPCODE_BRANCH = 7'b1100011;   // Branch instructions (B-type format)
parameter OPCODE_JAL = 7'b1101111;  // Jump and link (J-type)
parameter OPCODE_LUI = 7'b0110111;  // Load upper immediate (U-type)
parameter OPCODE_AUIPC = 7'b0010111;    // Add upper immediate to PC (U-type)

always @* begin
    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];
    
    // Decode instruction type based on opcode
    R_type = (opcode == OPCODE_R);
    I_type = (opcode == OPCODE_I) | (opcode == OPCODE_LOAD);
    S_type = (opcode == OPCODE_STORE);
    B_type = (opcode == OPCODE_BRANCH);
    U_type = (opcode == OPCODE_LUI) | (opcode == OPCODE_AUIPC);
    J_type = (opcode == OPCODE_JAL);
    
    // Decode immediate value based on instruction type
    if (R_type) begin
        funct7 = instr[31:25];
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end else if (I_type) begin
        imm = { {20{instr[31]}}, instr[31:20] };
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end else if (S_type) begin
        imm = { {20{instr[31]}}, instr[31:25], instr[11:7] };
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
    end else if (B_type) begin
        imm = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
    end else if (U_type) begin
        imm = { instr[31:12], 12'b0 };
        rd = instr[11:7];
    end else if (J_type) begin
        imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
        rd = instr[11:7];
    end
end

endmodule






module ALU (
    input [31:0] A,          // Operand A
    input [31:0] B,          // Operand B
    input [3:0]  funct3,     // ALU operation function code (subset of the funct3 field)
    input funct7,            // Used for discerning between ADD and SUB
    
    output reg [31:0] result, // Result of the operation
    output reg zero,         // Zero flag, 1 if result is 0
    output reg overflow      // Overflow flag for addition and subtraction
);

// Define funct3 codes
parameter ADD_SUB = 3'b000;
parameter SLL     = 3'b001;
parameter SLT     = 3'b010;
// TODO: add the rest of the funct3 codes here

always @* begin
    case(funct3)
        ADD_SUB: begin
            if (funct7 == 7'b0000000) // ADD
                result = A + B;
            else if (funct7 == 7'b0100000) // SUB
                result = A - B;
        end
        
        SLL: result = A << B[4:0];
        SLT: result = (A < B) ? 1 : 0;
        XOR: result = A ^ B;
        SRL_SRA: begin
            if (funct7 == 7'b0000000) // SRL
                result = A >> B[4:0];
            else if (funct7 == 7'b0100000) // SRA
                result = $signed(A) >>> B[4:0];
        end
        OR:  result = A | B;
        AND: result = A & B;
        default: result = 32'b0; // Default case
    endcase

    // Zero flag
    zero = (result == 0);

    // Overflow detection for ADD and SUB
    if (funct3 == ADD_SUB) begin
        if (funct7 == 7'b0000000) // ADD overflow
            overflow = (A[31] & B[31] & ~result[31]) | (~A[31] & ~B[31] & result[31]);
        else if (funct7 == 7'b0100000) // SUB overflow
            overflow = (A[31] & ~B[31] & ~result[31]) | (~A[31] & B[31] & result[31]);
    end else
        overflow = 0;
end

endmodule