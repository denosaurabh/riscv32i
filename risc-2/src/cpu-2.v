// https://www.fromthetransistor.com

module CPU (
    input clk,
    input reset,

    output wire [31:0] out_istr,

    output wire [6:0] o_funct7,
    output wire [2:0] o_funct3,
    output wire [4:0] o_opcode,
    output wire [31:0] o_imm
);

// RAM
reg [31:0] RAM[0:255]; // RAM with 32-bits x 256


// COUNTER & INSTRUCTION MEMORY
reg [31:0] pc;
reg [31:0] istr_adr = 32'b0;


// REGISTERS
reg [31:0] zero = 32'b0; // x0
reg [31:0] ra; // x1
reg [31:0] sp; // x2
reg [31:0] gp; // x3
reg [31:0] tp; // x4
reg [31:0] t[0:6]; // x5-x7, x28-x31
reg [31:0] s[0:11];  // x8-x9, x18-x27
reg [31:0] a[0:7];  // x10-x17




// INITIAL BEGIN
initial begin
    $display("CPU: Initial begin");

    // Initialize memory with some instructions. This is just a placeholder.
    // In a real scenario, the program or compiler output would populate this.
    RAM[0] = 32'b11111111110000010000000100010011; 
    RAM[1] = 32'b00000000001100010000000010110011;  
    RAM[2] = 32'b00000000001000100000000100010011;  
    RAM[3] = 32'b11111111110000010000000100010011;  
    RAM[4] = 32'b00000000001000100000000100010011;
    
end


always @(posedge clk or posedge reset) begin
    // FETCH
    if (reset) begin
        pc <= 32'b0;
    end else begin
        pc <= pc + 32'b1;
        istr_adr <= RAM[pc];
    end

    // DECODE
    // if (istr_adr) begin
    // RV32I_Decoder decoder (
    //     .instr(istr_adr),

    //     .funct7(funct7),
    //     .funct3(funct3),
    //     .opcode(opcode),
    //     .imm(imm),

    //     .R_type(r_type),
    //     .I_type(i_type),
    //     .S_type(s_type),
    //     .B_type(b_type),
    //     .U_type(u_type),
    //     .J_type(j_type)
    // );
    // end


    // EXECUTE
end



// DECODER
wire [6:0] funct7;
wire [2:0] funct3;
wire [4:0] opcode;
wire [31:0] imm;

wire r_type;
wire i_type;
wire s_type;
wire b_type;
wire u_type;
wire j_type;


RV32I_Decoder decoder (
    .instr(istr_adr),

    .funct7(funct7),
    .funct3(funct3),
    .opcode(opcode),
    .imm(imm),

    .R_type(r_type),
    .I_type(i_type),
    .S_type(s_type),
    .B_type(b_type),
    .U_type(u_type),
    .J_type(j_type)
);


// always @(posedge clk) begin

//     if (r_type) begin
//         // ALU
//         ALU alu (
//             .A(32'b0),
//             .B(32'b0),
//             .funct3(funct3),
//             .funct7(funct7),
//             .result(),
//             .zero(),
//             .overflow()
//         );
//     end

// end



assign out_istr = istr_adr;

assign o_funct7 = funct7;
assign o_funct3 = funct3;
assign o_opcode = opcode;
assign o_imm = imm;


endmodule;








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


// define rs2, rs1, rd
reg [4:0] rs2, rs1, rd;

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
    input enable,
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
    if (!enable) begin
        result = 32'b0;
        zero = 1'b0;
        overflow = 1'b0;
    end else begin
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
end

endmodule