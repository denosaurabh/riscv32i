module CPU (
    input clk,
    input reset
);

// COUNTER & INSTRUCTION MEMORY
wire [31:0] pc;
reg [31:0] next_pc;
reg [31:0] pc_reg;

wire [31:0] instruction;


// DATA RAM
reg [31:0] RAM[0:255]; // RAM with 32-bits x 256

// REGISTERS
reg [31:0] regs[0:31]; // 31-bit x 32 registers



/* *********************************** */
// PROGRAM COUNTER
ProgramCounter program_counter (
    .clk(clk),
    .reset(reset),

    .next_pc(next_pc),
    .pc(pc)
);



/* *********************************** */
// FETCH
InstructionMemory instr_mem (
    .address(pc),
    .instruction(instruction)
);


/* *********************************** */
// DECODE
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm;

wire [4:0] rs2;
wire [4:0] rs1;
wire [4:0] rd;

wire r_type;
wire i_type;
wire s_type;
wire b_type;
wire u_type;
wire j_type;
wire ecall_type;


RV32I_Decoder decoder (
    .instr(instruction),

    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .imm(imm),

    .rs2(rs2),
    .rs1(rs1),
    .rd(rd),

    .R_type(r_type),
    .I_type(i_type),
    .S_type(s_type),
    .B_type(b_type),
    .U_type(u_type),
    .J_type(j_type),
    .ECALL_type(ecall_type)
);




/* *********************************** */
// EXECUTE


// always @(posedge clk or posedge reset) begin
//     if (reset) begin
//         pc_reg <= 32'b0;
//     end else begin
//         pc_reg <= pc; // Store the current PC
//     end
// end


// always @(*) begin
always @(posedge clk) begin
    $display("[PC]");

    if (j_type) begin // JAL opcode
        $display("JAL imm: %d", imm);

        regs[rd] = pc + 4;
        next_pc = pc + imm; // Jump to the target address

    end else if (i_type) begin

        case (opcode)
            7'b1100111: begin
                $display("JALR");

                regs[rd] = pc + 4;
                next_pc = (regs[rs1] + imm) & ~1; // Compute target address, ensure LSB is 0
            end
            default: begin
                next_pc = pc + 4; // Default to next sequential instruction
            end
        endcase

    end else begin
        next_pc = pc + 4; // Default to next sequential instruction
    end

    $display("\n");
end



reg [31:0] s_type_adr;
reg [31:0] s_type_data;

// always @* begin
always @(posedge clk or posedge reset) begin
    $display("program_counter = %b, %d", pc, pc);
    $display("instruction: %b", instruction);

    if (reset) begin
        $display("reset");

        s_type_adr <= 32'b0;
        s_type_data <= 32'b0;

    end else begin
        // ALU
        if (r_type) begin

            $display("R-type");
            regs[rd] = ALU(1'b1, regs[rs1], regs[rs2], funct3, funct7);
            $display("rd = %b", regs[rd]);

        end else if (i_type) begin
            $display("I-type");

            case (opcode) 
                7'b0000011: begin
                    $display("LOAD");
                end
                7'b0010011: begin
                    $display("ALU");
                    regs[rd] = ALU(1'b1, regs[rs1], imm, funct3, 7'b0);
                    $display("rd = %b", regs[rd]);
                end
            endcase


        end else if (s_type) begin
            // TODO: TEST
            $display("S-type");

            s_type_adr = regs[rs1] + imm;
            s_type_data = regs[rs2];

            case (funct3) 
                3'b000: begin
                    $display("BYTE");
                    RAM[regs[rs1] + imm] = regs[rs2];

                    case (s_type_adr[1:0])
                        2'b00: RAM[s_type_adr[31:2]][7:0] <= s_type_data[7:0];
                        2'b01: RAM[s_type_adr[31:2]][15:8] <= s_type_data[7:0];
                        2'b10: RAM[s_type_adr[31:2]][23:16] <= s_type_data[7:0];
                        2'b11: RAM[s_type_adr[31:2]][31:24] <= s_type_data[7:0];
                    endcase

                end
                3'b001: begin
                    $display("HALF");

                    case (s_type_adr[1])
                        1'b0: RAM[s_type_adr[31:2]][15:0] <= s_type_data[15:0];
                        1'b1: RAM[s_type_adr[31:2]][31:16] <= s_type_data[15:0];
                    endcase

                end
                3'b010: begin
                    $display("WORD");

                    RAM[s_type_adr[31:2]] <= s_type_data;

                end

            endcase
        end else if (b_type) begin
            $display("B-type");
        end else if (u_type) begin
            $display("U-type");

            case (opcode) 
                7'b0110111: begin // LUI
                    $display("LUI");

                    // TODO: TEST it
                    // regs[rd] = imm >> 12;
                    regs[rd] = imm;
                    $display("rd = %b", regs[rd]);
                end
                7'b0010111: begin // AUIPC
                    $display("AUIPC");

                    // TODO: TEST it
                    // regs[rd] = pc + imm;
                    $display("rd = %b", regs[rd]);
                end
            endcase

        end else if (j_type) begin
            $display("J-type");

            regs[rd] = pc + 4;

            $display("pc_reg = %b", pc_reg);

        end else if (ecall_type) begin
            $display("ECALL");

            case (funct3)
                3'b000: begin
                    $display("ECALL PRINT: %b %d", regs[rd], regs[rd]);
                end
            endcase
        end
    end



    $display("\n");
end



endmodule;



/*
module ProgramCounter (
    input wire clk,
    input wire reset,
    input wire enable,

    input wire load,
    input wire [31:0] addr,
    
    output wire [31:0] pc
);

always @(posedge clk or posedge reset) begin
    
    if (reset) begin
        pc <= 32'b0;
    end else if (enable) begin
        if (load) begin
            // pc <= addr;
            assign pc = addr;
        end else begin
            // $display("pc: %b", pc);
            // pc <= pc + 4;
            assign pc = pc + 4;
        end
    end

end

endmodule
*/


module ProgramCounter (
    input wire clk,
    input wire reset,

    input wire [31:0] next_pc,

    output reg [31:0] pc
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 32'b0; // Reset PC to 0
    end else begin
        pc <= next_pc; // Update PC to the next instruction address
    end
end

endmodule




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



/*
module InstructionMemory (
    input clk,
    input reset,
    input wire [31:0] addr,

    output wire [31:0] instruction
);

reg [31:0] RAM[0:255]; // RAM with 32-bits x 256

always @(posedge clk) begin
    if (reset) begin
        // instruction <= 32'b0;
        assign instruction = 32'b0;
    end else begin
        // Fetch instruction based on address. Address is divided by 4 (shifted right by 2 bits) 
        // because each instruction is 4 bytes (32 bits) wide.
        // instruction <= RAM[addr >> 2];
        assign instruction = RAM[addr >> 2];
        // instruction <= RAM[addr];
    end
end


initial begin
    $readmemb("instructions.bin", RAM);
end



endmodule
*/




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

    output reg R_type,  // Signal indicating R-type instruction
    output reg I_type,  // Signal indicating I-type instruction
    output reg S_type,   // Signal indicating S-type instruction
    output reg B_type,
    output reg U_type,
    output reg J_type,
    output reg ECALL_type
);

parameter OPCODE_R = 7'b0110011; // R-type
parameter OPCODE_I = 7'b0010011; // I-type (immediate operations)
parameter OPCODE_LOAD = 7'b0000011; // Load instructions (I-type format)
parameter OPCODE_STORE = 7'b0100011; // Store instructions (S-type format)
parameter OPCODE_BRANCH = 7'b1100011;   // Branch instructions (B-type format)
parameter OPCODE_JAL = 7'b1101111;  // Jump and link (J-type)
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
    I_type = (opcode == OPCODE_I) | (opcode == OPCODE_LOAD);
    S_type = (opcode == OPCODE_STORE);
    B_type = (opcode == OPCODE_BRANCH);
    U_type = (opcode == OPCODE_LUI) | (opcode == OPCODE_AUIPC);
    J_type = (opcode == OPCODE_JAL);
    ECALL_type = (opcode == OPCODE_ECALL);
    
    // Decode immediate value based on instruction type
    if (R_type) begin
        funct7 = instr[31:25];
        rs2 = instr[24:20];
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end else if (I_type) begin
        imm = { {20{instr[31]}}, instr[31:20] };
        rs2 = 5'b0; // instr[24:20]
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
    end else if (ECALL_type) begin
        imm = { {20{instr[31]}}, instr[31:20] };
        rs2 = 5'b0;
        rs1 = instr[19:15];
        funct3 = instr[14:12];
        rd = instr[11:7];
    end
end

endmodule








// CREDIT: https://www.fromthetransistor.com
function [31:0] ALU;

input enable;

input [31:0] A;          // Operand A
input [31:0] B;          // Operand B

input [2:0] funct3;     // ALU operation function code (subset of the funct3 field)
input [6:0] funct7;            // Used for discerning between ADD and SUB

// output [31:0] result; // Result of the operation
// output reg zero,         // Zero flag, 1 if result is 0
// output reg overflow      // Overflow flag for addition and subtraction

// funct3 codes
parameter ADD_SUB = 3'b000;
parameter SLL     = 3'b001;
parameter SLT     = 3'b010;
parameter SLTU    = 3'b011;
parameter XOR     = 3'b100;
parameter SRL_SRA = 3'b101;
parameter OR      = 3'b110;
parameter AND     = 3'b111;

// funct7 codes
parameter STARD = 7'b0000000; // STANDARD
parameter ALTER = 7'b0100000; // ALTERNATE

if (!enable) begin
    ALU = 32'b0;
    // zero = 1'b0;
    // overflow = 1'b0;
end else begin

    case(funct3)
        ADD_SUB: begin
            if (funct7 == STARD)
                ALU = A + B;
            else if (funct7 == ALTER)
                ALU = A - B;
        end
        
        SLL: ALU = A << B[4:0];
        SLT: ALU = (A < B) ? 1 : 0;
        SLTU: ALU = (A < B) ? 1 : 0; // !TODO
        XOR: ALU = A ^ B;
        SRL_SRA: begin
            if (funct7 == STARD)
                ALU = A >> B[4:0];
            else if (funct7 == ALTER)
                ALU = $signed(A) >>> B[4:0];
        end
        OR:  ALU = A | B;
        AND: ALU = A & B;
        default: ALU = 32'b0;
    endcase

    // Zero flag
    // zero = (result == 0);

    // // Overflow detection for ADD and SUB
    // if (funct3 == ADD_SUB) begin
    //     if (funct7 == STARD) // ADD overflow
    //         overflow = (A[31] & B[31] & ~result[31]) | (~A[31] & ~B[31] & result[31]);
    //     else if (funct7 == ALTER) // SUB overflow
    //         overflow = (A[31] & ~B[31] & ~result[31]) | (~A[31] & B[31] & result[31]);
    // end else
    //     overflow = 0;

end

endfunction







/*







module ALU (
    input enable,

    input [31:0] A,          // Operand A
    input [31:0] B,          // Operand B
    
    input [2:0] funct3,     // ALU operation function code (subset of the funct3 field)
    input [6:0] funct7,            // Used for discerning between ADD and SUB
    
    output reg [31:0] result, // Result of the operation
    output reg zero,         // Zero flag, 1 if result is 0
    output reg overflow      // Overflow flag for addition and subtraction
);

// funct3 codes
parameter ADD_SUB = 3'b000;
parameter SLL     = 3'b001;
parameter SLT     = 3'b010;
parameter SLTU    = 3'b011;
parameter XOR     = 3'b100;
parameter SRL_SRA = 3'b101;
parameter OR      = 3'b110;
parameter AND     = 3'b111;

// funct7 codes
parameter STARD = 7'b0000000; // STANDARD
parameter ALTER = 7'b0100000; // ALTERNATE

always @* begin
    if (!enable) begin
        result = 32'b0;
        zero = 1'b0;
        overflow = 1'b0;
    end else begin

        case(funct3)
            ADD_SUB: begin
                if (funct7 == STARD)
                    result = A + B;
                else if (funct7 == ALTER)
                    result = A - B;
            end
            
            SLL: result = A << B[4:0];
            SLT: result = (A < B) ? 1 : 0;
            SLTU: result = (A < B) ? 1 : 0; // !TODO
            XOR: result = A ^ B;
            SRL_SRA: begin
                if (funct7 == STARD)
                    result = A >> B[4:0];
                else if (funct7 == ALTER)
                    result = $signed(A) >>> B[4:0];
            end
            OR:  result = A | B;
            AND: result = A & B;
            default: result = 32'b0;
        endcase

        // Zero flag
        zero = (result == 0);

        // Overflow detection for ADD and SUB
        if (funct3 == ADD_SUB) begin
            if (funct7 == STARD) // ADD overflow
                overflow = (A[31] & B[31] & ~result[31]) | (~A[31] & ~B[31] & result[31]);
            else if (funct7 == ALTER) // SUB overflow
                overflow = (A[31] & ~B[31] & ~result[31]) | (~A[31] & B[31] & result[31]);
        end else
            overflow = 0;

    end
end

endmodule





*/
