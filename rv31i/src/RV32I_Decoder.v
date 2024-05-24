`include "opcode.v"


// CREDIT: https://www.fromthetransistor.com
module RV32I_Decoder (
    input [31:0] instr,  // 32-bit instruction input

    output reg [2:0] funct3, // funct3 field
    output reg [6:0] funct7, // funct7 field
    output reg [6:0] opcode, // opcode field
    output reg [31:0] imm,   // immediate value, sign-extended when necessary

    output reg [4:0] rs2, // Source register 2
    output reg [4:0] rs1, // Source register 1
    output reg [4:0] rd,  // Destination register

    output reg [3:0] op

    // output reg R_type,  // Signal indicating R-type instruction
    // output reg I_type,  // Signal indicating I-type instruction
    // output reg S_type,   // Signal indicating S-type instruction
    // output reg B_type,
    // output reg U_type,
    // output reg J_type,
    // output reg ECALL_type
);

parameter OPCODE_R = 7'b0110011; // R-type
parameter OPCODE_I = 7'b0010011; // I-type (immediate operations)
parameter OPCODE_LOAD = 7'b0000011; // Load instructions (I-type format)
parameter OPCODE_STORE = 7'b0100011; // Store instructions (S-type format)
parameter OPCODE_BRANCH = 7'b1100011;   // Branch instructions (B-type format)
parameter OPCODE_JAL = 7'b1101111;  // Jump and link (J-type)
parameter OPCODE_JALR = 7'b1100111;  // Jump and link (J-type)
parameter OPCODE_LUI = 7'b0110111;  // Load upper immediate (U-type)
parameter OPCODE_AUIPC = 7'b0010111;    // Add upper immediate to PC (U-type)
parameter OPCODE_ECALL = 7'b1110011;    // Add upper immediate to PC (U-type)

always @* begin
    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];

    // $display("opcode: %b", opcode);
    
    // Decode instruction type based on opcode
    R_type = (opcode == OPCODE_R);
    I_type = (opcode == OPCODE_I) | (opcode == OPCODE_LOAD) | (opcode == OPCODE_JALR);
    S_type = (opcode == OPCODE_STORE);
    B_type = (opcode == OPCODE_BRANCH);
    U_type = (opcode == OPCODE_LUI) | (opcode == OPCODE_AUIPC);
    J_type = (opcode == OPCODE_JAL);
    ECALL_type = (opcode == OPCODE_ECALL);
    
    // Decode immediate value based on instruction type
    if (R_type) begin
        op = OP_R_TYPE;
        funct7 = instr[31:25];
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end else if (I_type) begin
        op = OP_I_TYPE;
        imm = { {20{instr[31]}}, instr[31:20] };
        rs2 = 5'b0; // instr[24:20]
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end else if (S_type) begin
        op = OP_S_TYPE;
        imm = { {20{instr[31]}}, instr[31:25], instr[11:7] };
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
    end else if (B_type) begin
        op = OP_B_TYPE;
        imm = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
    end else if (U_type) begin
        op = OP_U_TYPE;
        imm = { instr[31:12], 12'b0 };
        rd = instr[11:7];
    end else if (J_type) begin
        op = OP_J_TYPE;
        imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
        rd = instr[11:7];
    end else if (ECALL_type) begin
        op = OP_ECALL_TYPE;
        imm = { {20{instr[31]}}, instr[31:20] };
        rs2 = 5'b0;
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end
end

endmodule
