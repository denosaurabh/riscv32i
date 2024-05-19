// https://www.fromthetransistor.com

module CPU (
    input clk,
    input reset,

    output wire [31:0] out_istr,

    output wire [2:0] o_funct3,
    output wire [6:0] o_funct7,
    output wire [6:0] o_opcode,
    output wire [31:0] o_imm
);

// COUNTER & INSTRUCTION MEMORY
reg [31:0] pc;
reg [31:0] instruction;

// DATA RAM
reg [31:0] RAM[0:255]; // RAM with 32-bits x 256

// REGISTERS
reg [31:0] regs [0:31]; // 32 registers
/*
reg [31:0] zero = 32'b0; // x0
reg [31:0] ra; // x1
reg [31:0] sp; // x2
reg [31:0] gp; // x3
reg [31:0] tp; // x4
reg [31:0] t[0:6]; // x5-x7, x28-x31
reg [31:0] s[0:11];  // x8-x9, x18-x27
reg [31:0] a[0:7];  // x10-x17
*/




/* *********************************** */
// FETCH
InstructionMemory instr_mem (
    .clk(clk),
    .reset(reset),
    .addr(pc),
    
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
    .J_type(j_type)
);




/* *********************************** */
// EXECUTE

// reg [31:0] alu_a;
// reg [31:0] alu_b;
// wire [31:0] alu_res;

// ALU alu (
//     .A(alu_a),
//     .B(alu_b),

//     .enable(1'b1),

//     .funct3(funct3),
//     .funct7(funct7),

//     .result(alu_res),
//     .zero(),
//     .overflow()
// );

reg [31:0] s_type_adr;
reg [31:0] s_type_data;

reg istr_mem_load = 1'b0;
reg [31:0] istr_mem_load_addr = 32'b0;

// always @* begin
always @(posedge clk or posedge reset) begin
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
                    regs[rd] = pc + imm;
                    $display("rd = %b", regs[rd]);
                end
            endcase

        end else if (j_type) begin
            $display("J-type");
        end
    end


$display("\n");

end



/* *********************************** */
// PROGRAM COUNTER
ProgramCounter program_counter (
    .clk(clk),
    .reset(reset),
    .enable(1'b1),

    .load(istr_mem_load),
    .addr(istr_mem_load_addr),
    
    .pc(pc)
);




assign out_istr = instruction;

assign o_funct3 = funct3;
assign o_funct7 = funct7;
assign o_opcode = opcode;
assign o_imm = imm;


endmodule;



module ProgramCounter (
    input wire clk,
    input wire reset,
    input wire enable,

    input wire load,
    input wire [31:0] addr,
    
    output reg [31:0] pc
);

always @(posedge clk or posedge reset) begin
    
    if (reset) begin
        pc <= 32'b0;
    end else if (enable) begin
        if (load) begin
            pc <= addr;
        end else begin
            // $display("pc: %b", pc);
            pc <= pc + 4;
        end
    end

end

endmodule





module InstructionMemory (
    input clk,
    input reset,
    input wire [31:0] addr,

    output reg [31:0] instruction
);

reg [31:0] RAM[0:255]; // RAM with 32-bits x 256

always @(posedge clk) begin
    if (reset) begin
        instruction <= 32'b0;
    end else begin
        // Fetch instruction based on address. Address is divided by 4 (shifted right by 2 bits) 
        // because each instruction is 4 bytes (32 bits) wide.
        instruction <= RAM[addr >> 2];
        // instruction <= RAM[addr];
    end

    // always @(*) begin
    // Fetch instruction based on address. Address is divided by 4 (shifted right by 2 bits) 
    // because each instruction is 4 bytes (32 bits) wide.
    // instruction <= RAM[addr >> 2];
    // instruction = RAM[addr >> 2];
    // instruction = RAM[addr[31:2]];
end


initial begin
    // Initialize memory with some instructions. This is just a placeholder.
    // In a real scenario, the program or compiler output would populate this.
    
    // RAM[0] = 32'b00000000000001100100000100110111; // lui x2 100
    // RAM[1] = 32'b11111111110000010000000100010011; // addi x2 x2 -4


    // RAM[0] = 32'b00000000000001100100000100110111; // lui x2 100
    // RAM[1] = 32'b00000000000000000100000110110111; // lui x3 4
    // RAM[2] = 32'b00000000001100010000001000110011; // add x4 x2 x3


    RAM[0] = 32'b00000001110100100000010100110111;
    RAM[1] = 32'b00001010010101010000010100010011;
    RAM[2] = 32'b00000001011100100101010110110111;
    RAM[3] = 32'b00010110010001011000010110010011;
    RAM[4] = 32'b00000000101101010000011000110011;


    // RAM[0] = 32'b00000000001100010000000010110011;  // add ra sp gp (R-type)
    // RAM[1] = 32'b11111111110000010000000100010011; // addi x2 x2 -4
    // RAM[2] = 32'b00000000001000100000000100010011; // addi x2 x4 2
    // RAM[3] = 32'b11000100100100100100100100100101;  
    // RAM[4] = 32'b11100100100100100100100100100101;  
    // RAM[5] = 32'b11110100100100100100100100100101;  

    // ... more instructions ...
end



endmodule





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

    // $display("opcode: %b", opcode);
    
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
    end
end

endmodule









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